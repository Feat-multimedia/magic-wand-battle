import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/spell_model.dart';

class GestureService {
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  static final List<AccelerometerReading> _accelerometerReadings = [];
  static final List<GyroscopeReading> _gyroscopeReadings = [];
  
  static bool _isRecording = false;
  static DateTime? _recordingStartTime;
  static Function(GestureData)? _onGestureRecorded;
  static Function(int)? _onRecordingProgress;

  /// Démarrer l'enregistrement d'un geste
  static Future<void> startRecording({
    required Function(GestureData) onGestureRecorded,
    Function(int)? onRecordingProgress,
    int maxDurationMs = 5000, // 5 secondes max
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

    // Démarrer l'écoute des capteurs
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (_isRecording) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _accelerometerReadings.add(AccelerometerReading(
            x: event.x,
            y: event.y,
            z: event.z,
            timestamp: timestamp,
          ));
          
          // Notifier le progrès
          if (_recordingStartTime != null && _onRecordingProgress != null) {
            final elapsed = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
            _onRecordingProgress!(elapsed);
          }
        }
      },
    );

    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        if (_isRecording) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _gyroscopeReadings.add(GyroscopeReading(
            x: event.x,
            y: event.y,
            z: event.z,
            timestamp: timestamp,
          ));
        }
      },
    );

    // Arrêter automatiquement après la durée max
    Timer(Duration(milliseconds: maxDurationMs), () {
      if (_isRecording) {
        stopRecording();
      }
    });
  }

  /// Arrêter l'enregistrement
  static void stopRecording() {
    if (!_isRecording) return;

    _isRecording = false;
    
    // Arrêter l'écoute des capteurs
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;

    // Calculer la durée et le seuil
    final duration = _recordingStartTime != null 
        ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
        : 0;
    
    final threshold = _calculateThreshold();

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

  /// Calculer le seuil de détection basé sur l'amplitude du mouvement
  static double _calculateThreshold() {
    if (_accelerometerReadings.isEmpty) return 0.0;

    // Calculer l'amplitude moyenne des mouvements
    double totalAmplitude = 0.0;
    int count = 0;

    for (int i = 1; i < _accelerometerReadings.length; i++) {
      final current = _accelerometerReadings[i];
      final previous = _accelerometerReadings[i - 1];
      
      final deltaX = current.x - previous.x;
      final deltaY = current.y - previous.y;
      final deltaZ = current.z - previous.z;
      
      final amplitude = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);
      totalAmplitude += amplitude;
      count++;
    }

    // Retourner 70% de l'amplitude moyenne comme seuil
    return count > 0 ? (totalAmplitude / count) * 0.7 : 0.0;
  }

  /// Vérifier si un enregistrement est en cours
  static bool get isRecording => _isRecording;

  /// Obtenir la durée actuelle d'enregistrement
  static int get currentRecordingDuration {
    if (!_isRecording || _recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inMilliseconds;
  }

  /// Comparer deux gestes pour la reconnaissance
  static double compareGestures(GestureData recorded, GestureData target) {
    if (recorded.accelerometerReadings.isEmpty || target.accelerometerReadings.isEmpty) {
      return 0.0;
    }

    // Normaliser les durées (échantillonnage)
    final recordedNormalized = _normalizeGesture(recorded);
    final targetNormalized = _normalizeGesture(target);

    // Calculer la similarité
    double accelerometerSimilarity = _compareAccelerometerData(
      recordedNormalized.accelerometerReadings,
      targetNormalized.accelerometerReadings,
    );

    double gyroscopeSimilarity = _compareGyroscopeData(
      recordedNormalized.gyroscopeReadings,
      targetNormalized.gyroscopeReadings,
    );

    // Moyenne pondérée (accéléromètre plus important)
    return (accelerometerSimilarity * 0.7) + (gyroscopeSimilarity * 0.3);
  }

  /// Normaliser un geste pour la comparaison
  static GestureData _normalizeGesture(GestureData gesture) {
    const int targetSamples = 50; // Nombre d'échantillons cible
    
    if (gesture.accelerometerReadings.length <= targetSamples &&
        gesture.gyroscopeReadings.length <= targetSamples) {
      return gesture;
    }

    // Sous-échantillonner
    final accStep = gesture.accelerometerReadings.length / targetSamples;
    final gyroStep = gesture.gyroscopeReadings.length / targetSamples;

    final normalizedAcc = <AccelerometerReading>[];
    final normalizedGyro = <GyroscopeReading>[];

    for (int i = 0; i < targetSamples; i++) {
      final accIndex = (i * accStep).floor().clamp(0, gesture.accelerometerReadings.length - 1);
      final gyroIndex = (i * gyroStep).floor().clamp(0, gesture.gyroscopeReadings.length - 1);
      
      normalizedAcc.add(gesture.accelerometerReadings[accIndex]);
      normalizedGyro.add(gesture.gyroscopeReadings[gyroIndex]);
    }

    return GestureData(
      accelerometerReadings: normalizedAcc,
      gyroscopeReadings: normalizedGyro,
      threshold: gesture.threshold,
      duration: gesture.duration,
    );
  }

  /// Comparer les données d'accéléromètre
  static double _compareAccelerometerData(
    List<AccelerometerReading> data1,
    List<AccelerometerReading> data2,
  ) {
    if (data1.isEmpty || data2.isEmpty) return 0.0;

    final minLength = min(data1.length, data2.length);
    double totalDifference = 0.0;

    for (int i = 0; i < minLength; i++) {
      final diff1 = (data1[i].x - data2[i].x).abs();
      final diff2 = (data1[i].y - data2[i].y).abs();
      final diff3 = (data1[i].z - data2[i].z).abs();
      
      totalDifference += diff1 + diff2 + diff3;
    }

    // Convertir en pourcentage de similarité (plus la différence est faible, plus la similarité est élevée)
    final averageDifference = totalDifference / (minLength * 3);
    return max(0.0, 1.0 - (averageDifference / 10.0)); // Ajustable selon les tests
  }

  /// Comparer les données de gyroscope
  static double _compareGyroscopeData(
    List<GyroscopeReading> data1,
    List<GyroscopeReading> data2,
  ) {
    if (data1.isEmpty || data2.isEmpty) return 0.0;

    final minLength = min(data1.length, data2.length);
    double totalDifference = 0.0;

    for (int i = 0; i < minLength; i++) {
      final diff1 = (data1[i].x - data2[i].x).abs();
      final diff2 = (data1[i].y - data2[i].y).abs();
      final diff3 = (data1[i].z - data2[i].z).abs();
      
      totalDifference += diff1 + diff2 + diff3;
    }

    final averageDifference = totalDifference / (minLength * 3);
    return max(0.0, 1.0 - (averageDifference / 5.0)); // Gyroscope plus sensible
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