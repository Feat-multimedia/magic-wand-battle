import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/spell_model.dart';

import '../utils/logger.dart';

/// Service amélioré de reconnaissance gestuelle avec algorithmes robustes
class ImprovedGestureService {
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  static final List<AccelerometerReading> _accelerometerReadings = [];
  static final List<GyroscopeReading> _gyroscopeReadings = [];
  
  static bool _isRecording = false;
  static DateTime? _recordingStartTime;
  static Function(GestureData)? _onGestureRecorded;
  static Function(int)? _onRecordingProgress;

  // Filtre passe-bas pour réduire le bruit
  static AccelerometerEvent? _lastAccelEvent;
  static GyroscopeEvent? _lastGyroEvent;
  
  /// Démarrer l'enregistrement d'un geste
  static Future<void> startRecording({
    required Function(GestureData) onGestureRecorded,
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
    _accelerometerReadings.clear();
    _gyroscopeReadings.clear();
    _lastAccelEvent = null;
    _lastGyroEvent = null;

    // Démarrer l'écoute des capteurs avec filtrage
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (_isRecording) {
          // Appliquer un filtre passe-bas
          final filteredEvent = _applyLowPassFilter(event, _lastAccelEvent);
          _lastAccelEvent = filteredEvent;
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _accelerometerReadings.add(AccelerometerReading(
            x: filteredEvent.x,
            y: filteredEvent.y,
            z: filteredEvent.z,
            timestamp: timestamp,
          ));
          
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
          // Appliquer un filtre passe-bas
          final filteredEvent = _applyGyroLowPassFilter(event, _lastGyroEvent);
          _lastGyroEvent = filteredEvent;
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _gyroscopeReadings.add(GyroscopeReading(
            x: filteredEvent.x,
            y: filteredEvent.y,
            z: filteredEvent.z,
            timestamp: timestamp,
          ));
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

  /// Appliquer un filtre passe-bas à l'accéléromètre
  static AccelerometerEvent _applyLowPassFilter(AccelerometerEvent current, AccelerometerEvent? previous) {
    if (previous == null) return current;
    
    const double alpha = 0.8; // Facteur de lissage
    return AccelerometerEvent(
      alpha * current.x + (1 - alpha) * previous.x,
      alpha * current.y + (1 - alpha) * previous.y,
      alpha * current.z + (1 - alpha) * previous.z,
    );
  }

  /// Appliquer un filtre passe-bas au gyroscope
  static GyroscopeEvent _applyGyroLowPassFilter(GyroscopeEvent current, GyroscopeEvent? previous) {
    if (previous == null) return current;
    
    const double alpha = 0.8; // Facteur de lissage
    return GyroscopeEvent(
      alpha * current.x + (1 - alpha) * previous.x,
      alpha * current.y + (1 - alpha) * previous.y,
      alpha * current.z + (1 - alpha) * previous.z,
    );
  }

  /// Arrêter l'enregistrement
  static void stopRecording() {
    if (!_isRecording) return;

    _isRecording = false;
    
    // Arrêter les abonnements
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;

    // Calculer la durée et le seuil
    final duration = _recordingStartTime != null 
        ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
        : 0;
    
    final threshold = _calculateAdaptiveThreshold();

    Logger.info(' Geste enregistré (AMÉLIORÉ): ${_accelerometerReadings.length} points accél, ${_gyroscopeReadings.length} points gyro', tag: LogTags.stats);

    // Créer les données gestuelles
    final gestureData = GestureData(
      accelerometerReadings: List.from(_accelerometerReadings),
      gyroscopeReadings: List.from(_gyroscopeReadings),
      threshold: threshold,
      duration: duration,
    );

    // Notifier la fin de l'enregistrement
    _onGestureRecorded?.call(gestureData);
    
    // Nettoyer
    _onGestureRecorded = null;
    _onRecordingProgress = null;
    _recordingStartTime = null;
  }

  /// Calculer un seuil adaptatif basé sur l'énergie du mouvement
  static double _calculateAdaptiveThreshold() {
    if (_accelerometerReadings.isEmpty) return 0.0;

    // Calculer l'amplitude totale du mouvement
    double totalEnergy = 0.0;
    for (final reading in _accelerometerReadings) {
      final magnitude = sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
      totalEnergy += magnitude;
    }

    return totalEnergy / _accelerometerReadings.length;
  }

  /// 🚀 ALGORITHME AMÉLIORÉ - Comparer deux gestes de façon robuste
  static double compareGestures(GestureData recorded, GestureData target) {
    if (recorded.accelerometerReadings.isEmpty || target.accelerometerReadings.isEmpty) {
      return 0.0;
    }

    Logger.debug('🚀 === RECONNAISSANCE AMÉLIORÉE ===');
    Logger.debug('  Enregistré: ${recorded.accelerometerReadings.length} points, durée: ${recorded.duration}ms');
    Logger.debug('  Cible: ${target.accelerometerReadings.length} points, durée: ${target.duration}ms');

    // 1. Vérification de base - Durée cohérente
    final durationSimilarity = _compareDurations(recorded.duration, target.duration);
    if (durationSimilarity < 0.3) {
      Logger.debug('  ❌ Durées trop différentes: ${durationSimilarity * 100}%');
      return 0.0;
    }

    // 2. Calculer la similarité basée sur les magnitudes normalisées
    final magnitudeSimilarity = _compareMagnitudesRobust(recorded, target);
    Logger.debug('  📏 Similarité magnitude: ${(magnitudeSimilarity * 100).toStringAsFixed(1)}%');

    // 3. Calculer la similarité directionnelle (DTW-like)
    final directionSimilarity = _compareDirectionsRobust(recorded, target);
    Logger.debug('  🧭 Similarité direction: ${(directionSimilarity * 100).toStringAsFixed(1)}%');

    // 4. Calculer la similarité énergétique
    final energySimilarity = _compareEnergyProfiles(recorded, target);
    Logger.debug('  ⚡ Similarité énergie: ${(energySimilarity * 100).toStringAsFixed(1)}%');

    // 5. Score final pondéré avec seuils stricts
    final rawScore = (magnitudeSimilarity * 0.4) + 
                     (directionSimilarity * 0.4) + 
                     (energySimilarity * 0.2);
    
    // 6. Application de seuils adaptatifs
    final finalScore = _applyAdaptiveThreshold(rawScore, recorded, target);
    
    Logger.debug('  🎯 Score brut: ${(rawScore * 100).toStringAsFixed(1)}%');
    Logger.debug('  ✅ Score final: ${(finalScore * 100).toStringAsFixed(1)}%');
    return finalScore;
  }

  /// Comparer les magnitudes avec normalisation robuste
  static double _compareMagnitudesRobust(GestureData recorded, GestureData target) {
    // Calculer les magnitudes
    final recordedMagnitudes = recorded.accelerometerReadings.map((r) => 
        sqrt(r.x * r.x + r.y * r.y + r.z * r.z)).toList();
    final targetMagnitudes = target.accelerometerReadings.map((r) => 
        sqrt(r.x * r.x + r.y * r.y + r.z * r.z)).toList();

    // Normalisation temporelle avec interpolation
    final normalizedRecorded = _interpolateToFixedLength(recordedMagnitudes, 50);
    final normalizedTarget = _interpolateToFixedLength(targetMagnitudes, 50);

    // Normalisation d'amplitude (0-1)
    final normalizedRecordedAmplitude = _normalizeAmplitude(normalizedRecorded);
    final normalizedTargetAmplitude = _normalizeAmplitude(normalizedTarget);

    // Calculer la corrélation
    return _calculateCorrelation(normalizedRecordedAmplitude, normalizedTargetAmplitude);
  }

  /// Comparer les directions avec approche DTW simplifiée
  static double _compareDirectionsRobust(GestureData recorded, GestureData target) {
    // Calculer les vecteurs de direction
    final recordedDirections = _calculateDirectionVectors(recorded.accelerometerReadings);
    final targetDirections = _calculateDirectionVectors(target.accelerometerReadings);

    if (recordedDirections.isEmpty || targetDirections.isEmpty) {
      return 0.0;
    }

    // DTW simplifié pour aligner les séquences
    return _simpleDTW(recordedDirections, targetDirections);
  }

  /// Comparer les profils énergétiques
  static double _compareEnergyProfiles(GestureData recorded, GestureData target) {
    final recordedEnergy = _calculateEnergyProfile(recorded.accelerometerReadings);
    final targetEnergy = _calculateEnergyProfile(target.accelerometerReadings);

    if (recordedEnergy == 0.0 && targetEnergy == 0.0) return 1.0;
    if (recordedEnergy == 0.0 || targetEnergy == 0.0) return 0.0;

    // Ratio d'énergie avec tolérance
    final ratio = min(recordedEnergy, targetEnergy) / max(recordedEnergy, targetEnergy);
    return pow(ratio, 0.5).toDouble(); // Racine carrée pour être plus tolérant
  }

  /// Appliquer des seuils adaptatifs stricts
  static double _applyAdaptiveThreshold(double rawScore, GestureData recorded, GestureData target) {
    // Seuil minimum ajusté
    const double MIN_THRESHOLD = 0.4; // 40% minimum - plus raisonnable
    
    if (rawScore < MIN_THRESHOLD) {
      return 0.0; // Rejet total
    }

    // Bonus pour cohérence
    final coherenceBonus = _calculateCoherenceBonus(recorded, target);
    final adjustedScore = rawScore * (1.0 + coherenceBonus * 0.1);

    return adjustedScore.clamp(0.0, 1.0);
  }

  /// Calculer un bonus de cohérence
  static double _calculateCoherenceBonus(GestureData recorded, GestureData target) {
    // Bonus si les durées sont similaires
    final durationBonus = _compareDurations(recorded.duration, target.duration);
    
    // Bonus si le nombre de points est similaire
    final lengthRatio = min(recorded.accelerometerReadings.length, target.accelerometerReadings.length) /
                       max(recorded.accelerometerReadings.length, target.accelerometerReadings.length);
    
    return (durationBonus + lengthRatio) / 2.0;
  }

  /// Interpoler une séquence à une longueur fixe
  static List<double> _interpolateToFixedLength(List<double> sequence, int targetLength) {
    if (sequence.length <= 1) return List.filled(targetLength, 0.0);
    if (sequence.length == targetLength) return List.from(sequence);

    final result = <double>[];
    final step = (sequence.length - 1) / (targetLength - 1);
    
    for (int i = 0; i < targetLength; i++) {
      final exactIndex = i * step;
      final lowerIndex = exactIndex.floor();
      final upperIndex = (lowerIndex + 1).clamp(0, sequence.length - 1);
      final fraction = exactIndex - lowerIndex;
      
      final interpolated = sequence[lowerIndex] * (1 - fraction) + 
                          sequence[upperIndex] * fraction;
      result.add(interpolated);
    }
    
    return result;
  }

  /// Normaliser l'amplitude d'une séquence
  static List<double> _normalizeAmplitude(List<double> sequence) {
    if (sequence.isEmpty) return [];
    
    final maxVal = sequence.reduce(max);
    final minVal = sequence.reduce(min);
    final range = maxVal - minVal;
    
    if (range == 0) return List.filled(sequence.length, 0.5);
    
    return sequence.map((val) => (val - minVal) / range).toList();
  }

  /// Calculer la corrélation entre deux séquences
  static double _calculateCorrelation(List<double> seq1, List<double> seq2) {
    if (seq1.length != seq2.length || seq1.isEmpty) return 0.0;
    
    final mean1 = seq1.reduce((a, b) => a + b) / seq1.length;
    final mean2 = seq2.reduce((a, b) => a + b) / seq2.length;
    
    double numerator = 0.0;
    double denominator1 = 0.0;
    double denominator2 = 0.0;
    
    for (int i = 0; i < seq1.length; i++) {
      final diff1 = seq1[i] - mean1;
      final diff2 = seq2[i] - mean2;
      
      numerator += diff1 * diff2;
      denominator1 += diff1 * diff1;
      denominator2 += diff2 * diff2;
    }
    
    final denominator = sqrt(denominator1 * denominator2);
    if (denominator == 0) return 0.0;
    
    return (numerator / denominator).abs(); // Valeur absolue pour similarité
  }

  /// Calculer les vecteurs de direction
  static List<Point3D> _calculateDirectionVectors(List<AccelerometerReading> readings) {
    if (readings.length < 2) return [];

    final directions = <Point3D>[];
    for (int i = 1; i < readings.length; i++) {
      final prev = readings[i - 1];
      final curr = readings[i];
      
      final dx = curr.x - prev.x;
      final dy = curr.y - prev.y;
      final dz = curr.z - prev.z;
      
      final magnitude = sqrt(dx * dx + dy * dy + dz * dz);
      if (magnitude > 0.05) { // Seuil plus strict pour ignorer le bruit
        directions.add(Point3D(
          dx / magnitude,
          dy / magnitude,
          dz / magnitude,
        ));
      }
    }

    return directions;
  }

  /// DTW simplifié pour comparer les directions
  static double _simpleDTW(List<Point3D> seq1, List<Point3D> seq2) {
    if (seq1.isEmpty || seq2.isEmpty) return 0.0;
    
    final m = seq1.length;
    final n = seq2.length;
    
    // Matrice DTW simplifiée (seulement dernière ligne)
    var previous = List.filled(n + 1, double.infinity);
    var current = List.filled(n + 1, double.infinity);
    
    previous[0] = 0.0;
    
    for (int i = 1; i <= m; i++) {
      current[0] = double.infinity;
      
      for (int j = 1; j <= n; j++) {
        final cost = _distanceBetweenDirections(seq1[i - 1], seq2[j - 1]);
        current[j] = cost + min(min(current[j - 1], previous[j]), previous[j - 1]);
      }
      
      final temp = previous;
      previous = current;
      current = temp;
    }
    
    final maxPossibleDistance = m + n;
    final normalizedDistance = previous[n] / maxPossibleDistance;
    
    return max(0.0, 1.0 - normalizedDistance);
  }

  /// Distance entre deux vecteurs de direction
  static double _distanceBetweenDirections(Point3D dir1, Point3D dir2) {
    final dotProduct = dir1.x * dir2.x + dir1.y * dir2.y + dir1.z * dir2.z;
    return 1.0 - dotProduct.abs(); // Distance angulaire normalisée
  }

  /// Calculer le profil énergétique total
  static double _calculateEnergyProfile(List<AccelerometerReading> readings) {
    if (readings.isEmpty) return 0.0;
    
    double totalEnergy = 0.0;
    for (final reading in readings) {
      final magnitude = sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
      totalEnergy += magnitude * magnitude;
    }
    
    return totalEnergy / readings.length;
  }

  /// Comparer les durées
  static double _compareDurations(int duration1, int duration2) {
    final maxDuration = max(duration1, duration2);
    final minDuration = min(duration1, duration2);
    
    if (maxDuration == 0) return 1.0;
    final ratio = minDuration / maxDuration;
    
    // Plus strict sur les durées
    return ratio > 0.5 ? ratio : 0.0;
  }

  /// Getters pour l'état actuel
  static bool get isRecording => _isRecording;
  static int get currentRecordingDuration {
    if (!_isRecording || _recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inMilliseconds;
  }

  /// Nettoyer les ressources
  static void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _isRecording = false;
    _accelerometerReadings.clear();
    _gyroscopeReadings.clear();
  }
}

/// Classe pour représenter un point 3D
class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);
} 