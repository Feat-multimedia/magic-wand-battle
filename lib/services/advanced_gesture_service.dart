import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/spell_model.dart';

/// Service avancé de reconnaissance gestuelle basé sur l'analyse de signaux
class AdvancedGestureService {
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  static final List<SensorReading> _accelerometerData = [];
  static final List<SensorReading> _gyroscopeData = [];
  
  static bool _isRecording = false;
  static DateTime? _recordingStartTime;
  static Function(GestureSignature)? _onGestureRecorded;
  static Function(int)? _onRecordingProgress;

  /// Démarrer l'enregistrement d'un geste
  static Future<void> startRecording({
    required Function(GestureSignature) onGestureRecorded,
    Function(int)? onRecordingProgress,
    int maxDurationMs = 5000,
  }) async {
    if (_isRecording) {
      throw Exception('Un enregistrement est déjà en cours');
    }

    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _onGestureRecorded = onGestureRecorded;
    _onRecordingProgress = onRecordingProgress;
    
    // Vider les anciennes données
    _accelerometerData.clear();
    _gyroscopeData.clear();

    // Démarrer l'écoute des capteurs avec filtrage
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (_isRecording) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          
          // Appliquer un filtre passe-bas pour réduire le bruit
          final filteredReading = _applyLowPassFilter(
            SensorReading(
              x: event.x,
              y: event.y,
              z: event.z,
              timestamp: timestamp,
            ),
            _accelerometerData,
          );
          
          _accelerometerData.add(filteredReading);
          
          // Notifier le progrès
          if (_recordingStartTime != null && _onRecordingProgress != null) {
            final elapsed = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
            final progress = (elapsed / maxDurationMs * 100).clamp(0, 100).toInt();
            _onRecordingProgress!(progress);
          }
        }
      },
    );

    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        if (_isRecording) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          
          // Appliquer un filtre passe-bas pour réduire le bruit
          final filteredReading = _applyLowPassFilter(
            SensorReading(
              x: event.x,
              y: event.y,
              z: event.z,
              timestamp: timestamp,
            ),
            _gyroscopeData,
          );
          
          _gyroscopeData.add(filteredReading);
        }
      },
    );

    // Arrêt automatique après maxDurationMs
    Timer(Duration(milliseconds: maxDurationMs), () {
      if (_isRecording) {
        stopRecording();
      }
    });
  }

  /// Appliquer un filtre passe-bas pour réduire le bruit
  static SensorReading _applyLowPassFilter(SensorReading current, List<SensorReading> history) {
    if (history.isEmpty) return current;
    
    const double alpha = 0.8; // Facteur de lissage
    final previous = history.last;
    
    return SensorReading(
      x: alpha * current.x + (1 - alpha) * previous.x,
      y: alpha * current.y + (1 - alpha) * previous.y,
      z: alpha * current.z + (1 - alpha) * previous.z,
      timestamp: current.timestamp,
    );
  }

  /// Arrêter l'enregistrement et créer la signature gestuelle
  static void stopRecording() {
    if (!_isRecording) return;

    _isRecording = false;
    
    // Arrêter les abonnements
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;

    // Créer la signature gestuelle
    final signature = _createGestureSignature();
    
    print('📊 Signature créée: ${signature.accelerometerFeatures.length} features accél, ${signature.gyroscopeFeatures.length} features gyro');
    
    // Notifier la fin de l'enregistrement
    _onGestureRecorded?.call(signature);
    
    // Nettoyer
    _onGestureRecorded = null;
    _onRecordingProgress = null;
    _recordingStartTime = null;
  }

  /// Créer une signature gestuelle basée sur l'analyse de signaux
  static GestureSignature _createGestureSignature() {
    // Calculer les features temporelles
    final accelFeatures = _extractTemporalFeatures(_accelerometerData);
    final gyroFeatures = _extractTemporalFeatures(_gyroscopeData);
    
    // Détecter les pics et les patterns
    final accelPeaks = _detectPeaks(_accelerometerData);
    final gyroPeaks = _detectPeaks(_gyroscopeData);
    
    // Calculer l'énergie du signal
    final accelEnergy = _calculateSignalEnergy(_accelerometerData);
    final gyroEnergy = _calculateSignalEnergy(_gyroscopeData);
    
    return GestureSignature(
      accelerometerFeatures: accelFeatures,
      gyroscopeFeatures: gyroFeatures,
      accelerometerPeaks: accelPeaks,
      gyroscopePeaks: gyroPeaks,
      accelerometerEnergy: accelEnergy,
      gyroscopeEnergy: gyroEnergy,
      duration: _accelerometerData.isNotEmpty && _accelerometerData.length > 1
          ? _accelerometerData.last.timestamp - _accelerometerData.first.timestamp
          : 0,
    );
  }

  /// Extraire les features temporelles d'un signal
  static List<double> _extractTemporalFeatures(List<SensorReading> data) {
    if (data.length < 10) return [];
    
    // Calculer la magnitude 3D pour chaque point
    final magnitudes = data.map((reading) => 
        sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z)
    ).toList();
    
    // Features statistiques
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) / magnitudes.length;
    final stdDev = sqrt(variance);
    final maxVal = magnitudes.reduce(max);
    final minVal = magnitudes.reduce(min);
    
    // Features de forme
    final derivatives = <double>[];
    for (int i = 1; i < magnitudes.length; i++) {
      derivatives.add(magnitudes[i] - magnitudes[i-1]);
    }
    
    final avgDerivative = derivatives.isNotEmpty 
        ? derivatives.reduce((a, b) => a + b) / derivatives.length 
        : 0.0;
    
    // Compter les changements de direction
    int directionChanges = 0;
    for (int i = 2; i < derivatives.length; i++) {
      if ((derivatives[i-1] > 0) != (derivatives[i] > 0)) {
        directionChanges++;
      }
    }
    
    return [
      mean,
      stdDev,
      maxVal,
      minVal,
      maxVal - minVal, // Range
      avgDerivative,
      directionChanges.toDouble(),
      magnitudes.length.toDouble(), // Nombre de points
    ];
  }

  /// Détecter les pics dans un signal
  static List<Peak> _detectPeaks(List<SensorReading> data) {
    if (data.length < 5) return [];
    
    final peaks = <Peak>[];
    final magnitudes = data.map((reading) => 
        sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z)
    ).toList();
    
    // Calculer le seuil adaptatif
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final stdDev = sqrt(magnitudes.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) / magnitudes.length);
    final threshold = mean + stdDev;
    
    // Détecter les pics
    for (int i = 2; i < magnitudes.length - 2; i++) {
      final current = magnitudes[i];
      final prev1 = magnitudes[i-1];
      final prev2 = magnitudes[i-2];
      final next1 = magnitudes[i+1];
      final next2 = magnitudes[i+2];
      
      // Pic local si plus grand que les voisins et au-dessus du seuil
      if (current > threshold && 
          current > prev1 && current > prev2 && 
          current > next1 && current > next2) {
        peaks.add(Peak(
          timestamp: data[i].timestamp,
          magnitude: current,
          index: i,
        ));
      }
    }
    
    return peaks;
  }

  /// Calculer l'énergie du signal
  static double _calculateSignalEnergy(List<SensorReading> data) {
    if (data.isEmpty) return 0.0;
    
    double energy = 0.0;
    for (final reading in data) {
      final magnitude = sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
      energy += magnitude * magnitude;
    }
    
    return energy / data.length; // Énergie moyenne
  }

  /// Comparer deux signatures gestuelles avec DTW (Dynamic Time Warping)
  static double compareGestureSignatures(GestureSignature signature1, GestureSignature signature2) {
    // Pondération des différentes métriques
    const double featureWeight = 0.4;
    const double peakWeight = 0.3;
    const double energyWeight = 0.3;
    
    // Comparer les features temporelles
    final featureSimilarity = _compareFeatures(
      signature1.accelerometerFeatures, 
      signature2.accelerometerFeatures,
    );
    
    // Comparer les pics
    final peakSimilarity = _comparePeaks(
      signature1.accelerometerPeaks, 
      signature2.accelerometerPeaks,
    );
    
    // Comparer l'énergie
    final energySimilarity = _compareEnergy(
      signature1.accelerometerEnergy, 
      signature2.accelerometerEnergy,
    );
    
    // Score final pondéré
    final finalScore = (featureSimilarity * featureWeight) + 
                      (peakSimilarity * peakWeight) + 
                      (energySimilarity * energyWeight);
    
    print('🔍 Comparaison détaillée:');
    print('   Features: ${(featureSimilarity * 100).toStringAsFixed(1)}%');
    print('   Pics: ${(peakSimilarity * 100).toStringAsFixed(1)}%');
    print('   Énergie: ${(energySimilarity * 100).toStringAsFixed(1)}%');
    print('   Score final: ${(finalScore * 100).toStringAsFixed(1)}%');
    
    return finalScore;
  }

  /// Comparer les features temporelles
  static double _compareFeatures(List<double> features1, List<double> features2) {
    if (features1.isEmpty || features2.isEmpty) return 0.0;
    
    final minLength = min(features1.length, features2.length);
    double totalDifference = 0.0;
    
    for (int i = 0; i < minLength; i++) {
      // Normaliser les features avant comparaison
      final normalized1 = features1[i];
      final normalized2 = features2[i];
      final difference = (normalized1 - normalized2).abs();
      totalDifference += difference;
    }
    
    final avgDifference = totalDifference / minLength;
    return max(0.0, 1.0 - (avgDifference / 10.0)); // Ajustable
  }

  /// Comparer les patterns de pics
  static double _comparePeaks(List<Peak> peaks1, List<Peak> peaks2) {
    if (peaks1.isEmpty && peaks2.isEmpty) return 1.0;
    if (peaks1.isEmpty || peaks2.isEmpty) return 0.0;
    
    // Comparer le nombre de pics
    final countSimilarity = 1.0 - ((peaks1.length - peaks2.length).abs() / max(peaks1.length, peaks2.length));
    
    // Comparer la distribution temporelle des pics
    final timingSimilarity = _compareTimingPatterns(peaks1, peaks2);
    
    return (countSimilarity + timingSimilarity) / 2;
  }

  /// Comparer les patterns temporels des pics
  static double _compareTimingPatterns(List<Peak> peaks1, List<Peak> peaks2) {
    if (peaks1.length < 2 || peaks2.length < 2) return 0.5;
    
    // Calculer les intervalles entre pics
    final intervals1 = <double>[];
    final intervals2 = <double>[];
    
    for (int i = 1; i < peaks1.length; i++) {
      intervals1.add((peaks1[i].timestamp - peaks1[i-1].timestamp).toDouble());
    }
    
    for (int i = 1; i < peaks2.length; i++) {
      intervals2.add((peaks2[i].timestamp - peaks2[i-1].timestamp).toDouble());
    }
    
    // Comparer les patterns d'intervalles
    if (intervals1.isEmpty || intervals2.isEmpty) return 0.5;
    
    final minLength = min(intervals1.length, intervals2.length);
    double similarity = 0.0;
    
    for (int i = 0; i < minLength; i++) {
      final ratio = min(intervals1[i], intervals2[i]) / max(intervals1[i], intervals2[i]);
      similarity += ratio;
    }
    
    return similarity / minLength;
  }

  /// Comparer l'énergie des signaux
  static double _compareEnergy(double energy1, double energy2) {
    if (energy1 == 0.0 && energy2 == 0.0) return 1.0;
    if (energy1 == 0.0 || energy2 == 0.0) return 0.0;
    
    final ratio = min(energy1, energy2) / max(energy1, energy2);
    return ratio;
  }

  /// Vérifier si un enregistrement est en cours
  static bool get isRecording => _isRecording;

  /// Nettoyer les ressources
  static void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _isRecording = false;
    _accelerometerData.clear();
    _gyroscopeData.clear();
  }
}

/// Modèle pour les données de capteurs
class SensorReading {
  final double x;
  final double y; 
  final double z;
  final int timestamp;

  SensorReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });
}

/// Modèle pour un pic détecté
class Peak {
  final int timestamp;
  final double magnitude;
  final int index;

  Peak({
    required this.timestamp,
    required this.magnitude,
    required this.index,
  });
}

/// Signature gestuelle basée sur l'analyse de signaux
class GestureSignature {
  final List<double> accelerometerFeatures;
  final List<double> gyroscopeFeatures;
  final List<Peak> accelerometerPeaks;
  final List<Peak> gyroscopePeaks;
  final double accelerometerEnergy;
  final double gyroscopeEnergy;
  final int duration;

  GestureSignature({
    required this.accelerometerFeatures,
    required this.gyroscopeFeatures,
    required this.accelerometerPeaks,
    required this.gyroscopePeaks,
    required this.accelerometerEnergy,
    required this.gyroscopeEnergy,
    required this.duration,
  });

  /// Convertir en GestureData pour compatibilité
  GestureData toGestureData() {
    // Cette méthode sera utilisée pour la compatibilité avec l'ancien système
    // En attendant la migration complète
    return GestureData(
      accelerometerReadings: [], // Legacy - ne pas utiliser
      gyroscopeReadings: [], // Legacy - ne pas utiliser
      threshold: accelerometerEnergy, // Utiliser l'énergie comme seuil
      duration: duration,
    );
  }
} 