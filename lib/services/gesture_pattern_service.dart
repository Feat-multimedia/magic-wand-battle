import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/spell_model.dart';

/// Service de reconnaissance gestuelle basé sur les patterns géométriques
class GesturePatternService {
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  static Timer? _realtimeAnalysisTimer;
  
  static final List<AccelerometerReading> _accelerometerReadings = [];
  static final List<GyroscopeReading> _gyroscopeReadings = [];
  
  static bool _isRecording = false;
  static DateTime? _recordingStartTime;
  static Function(GestureData)? _onGestureRecorded;
  static Function(int)? _onRecordingProgress;

  // Paramètres pour l'enregistrement manuel (contrôlé par l'utilisateur)
  static const int MIN_RECORDING_DURATION = 500; // 0.5 seconde minimum pour éviter clics accidentels
  static const int MAX_RECORDING_DURATION = 8000; // 8 secondes maximum (sécurité)
  static const double REALTIME_CONFIDENCE_THRESHOLD = 0.7; // Non utilisé en mode manuel

  /// Démarrer l'enregistrement d'un geste
  static Future<void> startRecording({
    required Function(GestureData) onGestureRecorded,
    Function(int)? onRecordingProgress,
    int maxDurationMs = MAX_RECORDING_DURATION,
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

    print('🎬 Démarrage enregistrement avec détection temps réel');
    print('🔬 DEBUG: Vérification fréquence de capture...');

    // CAPTEURS HAUTE FRÉQUENCE - MOUVEMENT COMPLET 3D !
    // Forcer la fréquence à 100Hz pour iOS
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: Duration(microseconds: 10000)).listen(
      (AccelerometerEvent event) {
        if (_isRecording) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final reading = AccelerometerReading(
            timestamp: timestamp,
            x: event.x,
            y: event.y,
            z: event.z,
          );
          _accelerometerReadings.add(reading);
          
          // Callback de progression
          _onRecordingProgress?.call(currentRecordingDuration);
        }
      },
    );

    // GYROSCOPE ESSENTIEL pour rotations complètes !
    // Forcer la fréquence à 100Hz pour iOS
    _gyroscopeSubscription = gyroscopeEventStream(samplingPeriod: Duration(microseconds: 10000)).listen(
      (GyroscopeEvent event) {
        if (_isRecording) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final reading = GyroscopeReading(
            timestamp: timestamp,
            x: event.x, // Rotation autour X (pitch)
            y: event.y, // Rotation autour Y (roll) 
            z: event.z, // Rotation autour Z (yaw)
          );
          _gyroscopeReadings.add(reading);
        }
      },
    );

    // 🚀 Mode manuel : Pas d'analyse temps réel, utilisateur contrôle
    // _startRealtimeAnalysis(); // Désactivé - contrôle manuel

    // Timer de sécurité seulement (pour éviter enregistrements infinis)
    Timer(Duration(milliseconds: maxDurationMs), () {
      if (_isRecording) {
        print('⏰ Sécurité - Arrêt après ${maxDurationMs}ms (limite système)');
        _finishRecording();
      }
    });
  }

  /// Démarrer l'analyse temps réel
  static void _startRealtimeAnalysis() {
    _realtimeAnalysisTimer?.cancel();
    _realtimeAnalysisTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      final currentDuration = currentRecordingDuration;
      
      // Analyser seulement après la durée minimum
      if (currentDuration >= MIN_RECORDING_DURATION && _accelerometerReadings.length >= 10) {
        _checkForPatternDetection();
      }
    });
  }

  /// Vérifier si le mouvement semble terminé (stabilité ou durée suffisante)
  static void _checkForPatternDetection() {
    if (_accelerometerReadings.isEmpty) return;

    final currentDuration = currentRecordingDuration;
    
    // Arrêt automatique après 1.5 secondes si mouvement stable
    if (currentDuration >= 1500) {
      if (_isMovementStable()) {
        print('✅ Mouvement stable détecté ! Arrêt automatique.');
        _finishRecording();
        return;
      }
    }

    // Arrêt forcé après 3 secondes maximum
    if (currentDuration >= MAX_RECORDING_DURATION) {
      print('⏰ Durée maximum atteinte - Arrêt automatique.');
      _finishRecording();
    }
  }

  /// Vérifier si le mouvement est stable (peu de changements récents)
  static bool _isMovementStable() {
    if (_accelerometerReadings.length < 20) return false;

    // Analyser les 10 derniers points
    final recentPoints = _accelerometerReadings.sublist(_accelerometerReadings.length - 10);
    
    // Calculer la variance des 10 derniers points
    double avgX = 0, avgY = 0, avgZ = 0;
    for (final point in recentPoints) {
      avgX += point.x;
      avgY += point.y;
      avgZ += point.z;
    }
    avgX /= recentPoints.length;
    avgY /= recentPoints.length;
    avgZ /= recentPoints.length;

    double variance = 0;
    for (final point in recentPoints) {
      final dx = point.x - avgX;
      final dy = point.y - avgY;
      final dz = point.z - avgZ;
      variance += dx * dx + dy * dy + dz * dz;
    }
    variance /= recentPoints.length;

    // Si variance faible, mouvement stable  
    const double STABILITY_THRESHOLD = 1.0; // Plus strict pour éviter arrêts trop tôt
    final isStable = variance < STABILITY_THRESHOLD;
    
    if (isStable) {
      print('📊 Mouvement stable détecté (variance: ${variance.toStringAsFixed(3)})');
    }
    
    return isStable;
  }

  /// Arrêter l'enregistrement
  static void stopRecording() {
    if (_isRecording) {
      print('🛑 Arrêt manuel de l\'enregistrement');
      _finishRecording();
    }
  }

  /// Finaliser l'enregistrement
  static void _finishRecording() {
    _isRecording = false;
    
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _realtimeAnalysisTimer?.cancel();

    final duration = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
    
    final gestureData = GestureData(
      accelerometerReadings: List.from(_accelerometerReadings),
      gyroscopeReadings: List.from(_gyroscopeReadings),
      threshold: 0.3, // Seuil par défaut
      duration: duration,
    );

    // DEBUG : Analyser la fréquence de capture
    final accelFreq = _accelerometerReadings.length / (duration / 1000.0);
    final gyroFreq = _gyroscopeReadings.length / (duration / 1000.0);
    
    print('🎯 Geste enregistré: ${_accelerometerReadings.length} points accelerometer, ${_gyroscopeReadings.length} points gyroscope');
    print('📈 Fréquences: Accel=${accelFreq.toStringAsFixed(1)}Hz, Gyro=${gyroFreq.toStringAsFixed(1)}Hz, Durée=${duration}ms');
    
    if (accelFreq < 20) {
      print('⚠️  PROBLÈME: Fréquence accelerometer trop faible ! Attendu: 50-100Hz');
    }
    
    _onGestureRecorded?.call(gestureData);
  }

  /// ============ RECONNAISSANCE DE PATTERNS ============

  /// Comparer deux gestes : mouvement enregistré vs mouvement à reproduire
  static double compareGestures(GestureData recorded, GestureData target) {
    print('\n🔍 === COMPARAISON MOUVEMENT ===');
    print('📊 User: ${recorded.accelerometerReadings.length} points, ${recorded.duration}ms');
    print('📊 Original: ${target.accelerometerReadings.length} points, ${target.duration}ms');

    if (recorded.accelerometerReadings.isEmpty || target.accelerometerReadings.isEmpty) {
      print('❌ Données vides');
      return 0.0;
    }

    // 1. GARDER TOUTES LES DONNÉES CAPTEURS ! Pas de perte stupide !
    print('🔍 Données brutes: User ${recorded.accelerometerReadings.length} points, Original ${target.accelerometerReadings.length} points');
    
    final userTrajectory = _extractTrajectory(recorded.accelerometerReadings);
    final originalTrajectory = _extractTrajectory(target.accelerometerReadings);

    print('🔍 Après extraction: User ${userTrajectory.length} points, Original ${originalTrajectory.length} points');

    if (userTrajectory.length < 2 || originalTrajectory.length < 2) {
      print('❌ Trajectoires trop courtes après extraction !');
      return 0.0;
    }

    // 2. Normaliser SANS PERDRE de points
    final normalizedUser = _normalizeTrajectory(userTrajectory);
    final normalizedOriginal = _normalizeTrajectory(originalTrajectory);
    
    print('🔍 Après normalisation: User ${normalizedUser.length} points, Original ${normalizedOriginal.length} points');

    print('📐 Trajectoires: ${normalizedUser.length} vs ${normalizedOriginal.length} points');

    // 3. COMPARAISON COMPLÈTE 3D + ROTATIONS
    
    // A. Similarité de trajectoire 3D (translations)
    final trajectorySimilarity = _compareTrajectoryShapes(normalizedUser, normalizedOriginal);
    
    // B. Similarité des ROTATIONS (gyroscope) - CRITIQUE !
    final rotationSimilarity = _compareRotations(recorded, target);
    
    // C. Similarité des caractéristiques de mouvement combinées
    final motionSimilarity = _compareMotionCharacteristics(recorded, target);
    
    // D. Similarité temporelle 
    final timingSimilarity = _compareTimingCharacteristics(recorded, target);

    print('🎯 3D: ${(trajectorySimilarity * 100).toStringAsFixed(1)}% | Rotation: ${(rotationSimilarity * 100).toStringAsFixed(1)}% | Motion: ${(motionSimilarity * 100).toStringAsFixed(1)}% | Timing: ${(timingSimilarity * 100).toStringAsFixed(1)}%');

    // 4. Score final - MOUVEMENT COMPLET 3D + ROTATIONS
    final finalScore = (
      trajectorySimilarity * 0.35 +  // 35% - Trajectoire 3D
      rotationSimilarity * 0.35 +    // 35% - Rotations (ESSENTIEL!)
      motionSimilarity * 0.20 +      // 20% - Caractéristiques mouvement  
      timingSimilarity * 0.10        // 10% - Timing
    ).clamp(0.0, 1.0);

    print('🏆 Score final: ${(finalScore * 100).toStringAsFixed(1)}%');
    
    return finalScore;
  }

  /// Comparer la forme des trajectoires avec détection directionnelle
  static double _compareTrajectoryShapes(List<Point3D> userTrajectory, List<Point3D> originalTrajectory) {
    if (userTrajectory.isEmpty || originalTrajectory.isEmpty) return 0.0;

    // Le problème est EN AMONT ! Pourquoi seulement 8 points ?!
    print('🔍 AVANT traitement: User ${userTrajectory.length} points, Original ${originalTrajectory.length} points');
    
    // CORRECTION : Utiliser le minimum de points pour éviter l'erreur
    final minPoints = min(userTrajectory.length, originalTrajectory.length);
    final standardSize = max(3, minPoints); // Au moins 3 points, sinon on prend ce qu'on a
    
    print('📏 Standardisation à ${standardSize} points (min des 2 trajectoires)');
    
    final resampledUser = _resampleTrajectory(userTrajectory, standardSize);
    final resampledOriginal = _resampleTrajectory(originalTrajectory, standardSize);

    if (resampledUser.length != standardSize || resampledOriginal.length != standardSize) {
      print('❌ ERREUR CRITIQUE rééchantillonnage: ${resampledUser.length} vs ${resampledOriginal.length} (attendu: ${standardSize})');
      // FALLBACK : Utiliser les trajectoires telles quelles
      final finalUser = userTrajectory.length <= originalTrajectory.length ? userTrajectory : userTrajectory.take(originalTrajectory.length).toList();
      final finalOriginal = originalTrajectory.length <= userTrajectory.length ? originalTrajectory : originalTrajectory.take(userTrajectory.length).toList();
      return _compareTrajectoryShapesFallback(finalUser, finalOriginal);
    }

    // 1. COMPARAISON DE FORME (positions)
    double totalDistance = 0.0;
    for (int i = 0; i < standardSize; i++) {
      totalDistance += _distance3D(resampledUser[i], resampledOriginal[i]);
    }
    final avgDistance = totalDistance / standardSize;
    final shapeSimilarity = max(0.0, 1.0 - (avgDistance * 1.5));

    // 2. COMPARAISON DIRECTIONNELLE (simplifiée pour debug)
    double directionSimilarity = 0.8; // Temporaire - plus permissif
    double sequenceSimilarity = 0.7;   // Temporaire - plus permissif
    
    try {
      final userDirection = _calculateMovementDirection(resampledUser);
      final originalDirection = _calculateMovementDirection(resampledOriginal);
      directionSimilarity = _compareDirections(userDirection, originalDirection);
      
      // 3. COMPARAISON DE SÉQUENCE TEMPORELLE
      sequenceSimilarity = _compareSequenceOrder(resampledUser, resampledOriginal);
    } catch (e) {
      print('⚠️ Erreur calcul direction/séquence: $e');
      // Utiliser les valeurs par défaut ci-dessus
    }

    print('🎯 Forme: ${(shapeSimilarity * 100).toStringAsFixed(1)}% | Direction: ${(directionSimilarity * 100).toStringAsFixed(1)}% | Séquence: ${(sequenceSimilarity * 100).toStringAsFixed(1)}%');

    // Score final : Forme prioritaire pour debug
    final finalSimilarity = (
      shapeSimilarity * 0.6 +        // 60% - Position (augmenté pour debug)
      directionSimilarity * 0.3 +    // 30% - Direction 
      sequenceSimilarity * 0.1       // 10% - Séquence
    ).clamp(0.0, 1.0);
    
    return finalSimilarity;
  }

  /// FALLBACK : Comparaison simple quand le rééchantillonnage échoue
  static double _compareTrajectoryShapesFallback(List<Point3D> traj1, List<Point3D> traj2) {
    if (traj1.isEmpty || traj2.isEmpty) return 0.0;
    
    print('🆘 FALLBACK: Comparaison directe ${traj1.length} vs ${traj2.length} points');
    
    // Comparaison point à point simple
    final minLength = min(traj1.length, traj2.length);
    double totalDistance = 0.0;
    
    for (int i = 0; i < minLength; i++) {
      totalDistance += _distance3D(traj1[i], traj2[i]);
    }
    
    final avgDistance = totalDistance / minLength;
    final similarity = max(0.0, 1.0 - (avgDistance * 1.0));
    
    print('🆘 FALLBACK Similarité: ${(similarity * 100).toStringAsFixed(1)}%');
    
    return similarity;
  }

  /// NOUVEAU : Calculer la direction générale du mouvement (horaire/anti-horaire)
  static MovementDirection _calculateMovementDirection(List<Point3D> trajectory) {
    if (trajectory.length < 3) return MovementDirection(type: 'linear', confidence: 0.5);

    // Calculer les angles entre points successifs
    final angles = <double>[];
    final center = _calculateCenter(trajectory);

    for (final point in trajectory) {
      final dx = point.x - center.x;
      final dy = point.y - center.y;
      if (dx != 0 || dy != 0) {
        angles.add(atan2(dy, dx));
      }
    }

    if (angles.length < 3) return MovementDirection(type: 'linear', confidence: 0.8);

    // Analyser les changements d'angle pour détecter la direction
    double totalAngleChange = 0.0;
    int directionChanges = 0;

    for (int i = 1; i < angles.length; i++) {
      double angleDiff = angles[i] - angles[i - 1];
      
      // Normaliser la différence d'angle
      while (angleDiff > pi) angleDiff -= 2 * pi;
      while (angleDiff < -pi) angleDiff += 2 * pi;
      
      totalAngleChange += angleDiff;
      if (angleDiff.abs() > pi / 6) directionChanges++; // 30°
    }

    // Déterminer le type de mouvement
    final avgAngleChange = totalAngleChange / (angles.length - 1);
    
    if (directionChanges < 2) {
      return MovementDirection(type: 'linear', confidence: 0.9);
    }
    
    if (totalAngleChange.abs() > pi) {
      // Mouvement circulaire détecté
      if (totalAngleChange > 0) {
        return MovementDirection(type: 'counterclockwise', confidence: 0.9);
      } else {
        return MovementDirection(type: 'clockwise', confidence: 0.9);
      }
    }
    
    // Mouvement complexe/zigzag
    return MovementDirection(type: 'complex', confidence: 0.7, features: {
      'directionChanges': directionChanges.toDouble(),
      'avgAngleChange': avgAngleChange,
    });
  }

  /// Calculer le centre d'une trajectoire
  static Point3D _calculateCenter(List<Point3D> trajectory) {
    if (trajectory.isEmpty) return const Point3D(0, 0, 0);
    
    double centerX = 0, centerY = 0, centerZ = 0;
    for (final point in trajectory) {
      centerX += point.x;
      centerY += point.y;
      centerZ += point.z;
    }
    
    return Point3D(
      centerX / trajectory.length,
      centerY / trajectory.length,
      centerZ / trajectory.length,
    );
  }

  /// CRITIQUE : Comparer les directions de mouvement
  static double _compareDirections(MovementDirection dir1, MovementDirection dir2) {
    print('🧭 Directions: "${dir1.type}" vs "${dir2.type}"');
    
    // Si types identiques = excellent
    if (dir1.type == dir2.type) {
      final avgConfidence = (dir1.confidence + dir2.confidence) / 2;
      return avgConfidence;
    }
    
    // DIRECTIONS OPPOSÉES = ÉCHEC TOTAL !!!
    if ((dir1.type == 'clockwise' && dir2.type == 'counterclockwise') ||
        (dir1.type == 'counterclockwise' && dir2.type == 'clockwise')) {
      print('❌ DIRECTIONS OPPOSÉES DÉTECTÉES !');
      return 0.0; // ÉCHEC TOTAL
    }
    
    // Autres cas : similarité partielle
    if ((dir1.type == 'linear' && dir2.type == 'complex') ||
        (dir1.type == 'complex' && dir2.type == 'linear')) {
      return 0.3; // Tolérance limitée
    }
    
    // Types complètement différents
    return 0.1;
  }

  /// Comparer l'ordre séquentiel des points
  static double _compareSequenceOrder(List<Point3D> traj1, List<Point3D> traj2) {
    if (traj1.length != traj2.length) return 0.5;
    
    // Calculer la corrélation séquentielle
    double correlation = 0.0;
    for (int i = 0; i < traj1.length - 1; i++) {
      final vec1 = Point3D(
        traj1[i + 1].x - traj1[i].x,
        traj1[i + 1].y - traj1[i].y,
        traj1[i + 1].z - traj1[i].z,
      );
      final vec2 = Point3D(
        traj2[i + 1].x - traj2[i].x,
        traj2[i + 1].y - traj2[i].y,
        traj2[i + 1].z - traj2[i].z,
      );
      
      // Produit scalaire normalisé
      final dot = vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z;
      final mag1 = sqrt(vec1.x * vec1.x + vec1.y * vec1.y + vec1.z * vec1.z);
      final mag2 = sqrt(vec2.x * vec2.x + vec2.y * vec2.y + vec2.z * vec2.z);
      
      if (mag1 > 0 && mag2 > 0) {
        correlation += dot / (mag1 * mag2);
      }
    }
    
    return max(0.0, correlation / (traj1.length - 1));
  }

  /// Rééchantillonner une trajectoire à un nombre de points donné
  static List<Point3D> _resampleTrajectory(List<Point3D> trajectory, int targetSize) {
    if (trajectory.isEmpty) return [];
    if (trajectory.length <= targetSize) return List.from(trajectory);
    if (targetSize <= 0) return [];
    
    final resampled = <Point3D>[];
    
    // Cas spécial pour 1 point
    if (targetSize == 1) {
      resampled.add(trajectory.first);
      return resampled;
    }
    
    // Rééchantillonnage linéaire sécurisé
    for (int i = 0; i < targetSize; i++) {
      final ratio = i / (targetSize - 1); // 0.0 à 1.0
      final exactIndex = ratio * (trajectory.length - 1);
      final index = exactIndex.round().clamp(0, trajectory.length - 1);
      resampled.add(trajectory[index]);
    }
    
    return resampled;
  }

  /// Comparer les caractéristiques de mouvement (vitesse, accélération, énergie)
  static double _compareMotionCharacteristics(GestureData user, GestureData original) {
    // 1. Comparer les profils de vitesse
    final userVelocities = _calculateVelocityProfile(user.accelerometerReadings);
    final originalVelocities = _calculateVelocityProfile(original.accelerometerReadings);
    final velocitySimilarity = _compareProfiles(userVelocities, originalVelocities);

    // 2. Comparer l'énergie totale du mouvement
    final userEnergy = _calculateTotalEnergy(user.accelerometerReadings);
    final originalEnergy = _calculateTotalEnergy(original.accelerometerReadings);
    final energyRatio = min(userEnergy, originalEnergy) / max(userEnergy, originalEnergy);
    final energySimilarity = energyRatio;

    // 3. Comparer les pics d'accélération
    final userPeaks = _countAccelerationPeaks(user.accelerometerReadings);
    final originalPeaks = _countAccelerationPeaks(original.accelerometerReadings);
    final peakSimilarity = userPeaks == originalPeaks ? 1.0 : 
                          (1.0 - ((userPeaks - originalPeaks).abs() / max(userPeaks, originalPeaks)));

    return (velocitySimilarity * 0.4 + energySimilarity * 0.4 + peakSimilarity * 0.2);
  }

  /// Calculer le profil de vitesse
  static List<double> _calculateVelocityProfile(List<AccelerometerReading> readings) {
    final velocities = <double>[];
    for (final reading in readings) {
      final magnitude = sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
      velocities.add(magnitude);
    }
    return velocities;
  }

  /// Calculer l'énergie totale du mouvement
  static double _calculateTotalEnergy(List<AccelerometerReading> readings) {
    double totalEnergy = 0.0;
    for (final reading in readings) {
      final magnitude = sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
      totalEnergy += magnitude * magnitude;
    }
    return totalEnergy / readings.length;
  }

  /// Compter les pics d'accélération
  static int _countAccelerationPeaks(List<AccelerometerReading> readings) {
    if (readings.length < 3) return 0;
    
    final magnitudes = readings.map((r) => 
      sqrt(r.x * r.x + r.y * r.y + r.z * r.z)).toList();
    
    int peaks = 0;
    for (int i = 1; i < magnitudes.length - 1; i++) {
      if (magnitudes[i] > magnitudes[i - 1] && magnitudes[i] > magnitudes[i + 1]) {
        peaks++;
      }
    }
    return peaks;
  }

  /// Comparer deux profils de données
  static double _compareProfiles(List<double> profile1, List<double> profile2) {
    if (profile1.isEmpty || profile2.isEmpty) return 0.0;
    
    // Normaliser les profils
    final norm1 = _normalizeProfile(profile1);
    final norm2 = _normalizeProfile(profile2);
    
    // Rééchantillonner à la même taille
    final standardSize = min(20, min(norm1.length, norm2.length));
    final resampled1 = _resampleProfile(norm1, standardSize);
    final resampled2 = _resampleProfile(norm2, standardSize);
    
    // Calculer la corrélation/similarité
    double totalDiff = 0.0;
    for (int i = 0; i < standardSize; i++) {
      totalDiff += (resampled1[i] - resampled2[i]).abs();
    }
    
    return max(0.0, 1.0 - (totalDiff / standardSize));
  }

  /// Normaliser un profil de données
  static List<double> _normalizeProfile(List<double> profile) {
    if (profile.isEmpty) return [];
    
    final maxVal = profile.reduce(max);
    final minVal = profile.reduce(min);
    final range = maxVal - minVal;
    
    if (range == 0) return profile.map((_) => 0.5).toList();
    
    return profile.map((val) => (val - minVal) / range).toList();
  }

  /// Rééchantillonner un profil
  static List<double> _resampleProfile(List<double> profile, int targetSize) {
    if (profile.isEmpty) return [];
    if (targetSize <= 0) return [];
    if (profile.length <= targetSize) return List.from(profile);
    
    final resampled = <double>[];
    
    // Cas spécial pour un seul point cible
    if (targetSize == 1) {
      resampled.add(profile.first);
      return resampled;
    }
    
    // Calcul sécurisé du pas
    final stepSize = (profile.length - 1) / (targetSize - 1);
    
    // Vérifier que stepSize est valide (pas NaN ou infini)
    if (!stepSize.isFinite || stepSize <= 0) {
      print('⚠️ stepSize invalide: $stepSize, utilisation linéaire');
      // Fallback: distribution linéaire simple
      for (int i = 0; i < targetSize; i++) {
        final ratio = i / (targetSize - 1);
        final index = (ratio * (profile.length - 1)).round().clamp(0, profile.length - 1);
        resampled.add(profile[index]);
      }
      return resampled;
    }
    
    for (int i = 0; i < targetSize; i++) {
      final exactIndex = i * stepSize;
      if (!exactIndex.isFinite) {
        print('⚠️ Index invalide: $exactIndex, utilisation fallback');
        resampled.add(profile[i.clamp(0, profile.length - 1)]);
        continue;
      }
      
      final index = exactIndex.round().clamp(0, profile.length - 1);
      resampled.add(profile[index]);
    }
    
    return resampled;
  }

  /// Comparer les aspects temporels des mouvements
  static double _compareTimingCharacteristics(GestureData user, GestureData original) {
    // 1. Similarité de durée
    final durationRatio = min(user.duration, original.duration) / max(user.duration, original.duration);
    final durationSimilarity = durationRatio > 0.5 ? durationRatio : 0.0; // Seuil minimum

    // 2. Similarité du rythme (variations temporelles)
    final userRhythm = _calculateRhythmPattern(user.accelerometerReadings);
    final originalRhythm = _calculateRhythmPattern(original.accelerometerReadings);
    final rhythmSimilarity = _compareProfiles(userRhythm, originalRhythm);

    return (durationSimilarity * 0.6 + rhythmSimilarity * 0.4);
  }

  /// Calculer le pattern de rythme du mouvement
  static List<double> _calculateRhythmPattern(List<AccelerometerReading> readings) {
    if (readings.length < 2) return [];
    
    final intervals = <double>[];
    for (int i = 1; i < readings.length; i++) {
      final interval = readings[i].timestamp - readings[i - 1].timestamp;
      intervals.add(interval.toDouble());
    }
    
    return intervals;
  }

  /// NOUVEAU : Comparer les rotations (gyroscope) - ESSENTIEL pour mouvements 3D complets
  static double _compareRotations(GestureData user, GestureData original) {
    if (user.gyroscopeReadings.isEmpty || original.gyroscopeReadings.isEmpty) {
      print('⚠️ Pas de données gyroscope - rotation ignorée');
      return 0.5; // Neutre si pas de données rotation
    }

    print('🌀 Comparaison rotations: ${user.gyroscopeReadings.length} vs ${original.gyroscopeReadings.length} points');

    // 1. Profils de rotation pour chaque axe
    final userRotX = user.gyroscopeReadings.map((r) => r.x).toList();
    final userRotY = user.gyroscopeReadings.map((r) => r.y).toList();
    final userRotZ = user.gyroscopeReadings.map((r) => r.z).toList();
    
    final originalRotX = original.gyroscopeReadings.map((r) => r.x).toList();
    final originalRotY = original.gyroscopeReadings.map((r) => r.y).toList();
    final originalRotZ = original.gyroscopeReadings.map((r) => r.z).toList();

    // 2. Comparer chaque axe de rotation
    final similarityX = _compareProfiles(userRotX, originalRotX);
    final similarityY = _compareProfiles(userRotY, originalRotY);
    final similarityZ = _compareProfiles(userRotZ, originalRotZ);

    // 3. Calculer la magnitude totale des rotations
    final userTotalRotation = _calculateTotalRotation(user.gyroscopeReadings);
    final originalTotalRotation = _calculateTotalRotation(original.gyroscopeReadings);
    final rotationRatio = min(userTotalRotation, originalTotalRotation) / 
                         max(userTotalRotation, originalTotalRotation);

    // 4. Score final rotation (moyenne pondérée)
    final rotationSimilarity = (
      similarityX * 0.3 +      // 30% - Pitch (rotation X)
      similarityY * 0.3 +      // 30% - Roll (rotation Y)  
      similarityZ * 0.3 +      // 30% - Yaw (rotation Z)
      rotationRatio * 0.1      // 10% - Intensité totale
    ).clamp(0.0, 1.0);

    print('🌀 Rotations X:${(similarityX*100).toStringAsFixed(1)}% Y:${(similarityY*100).toStringAsFixed(1)}% Z:${(similarityZ*100).toStringAsFixed(1)}% Total:${(rotationRatio*100).toStringAsFixed(1)}%');

    return rotationSimilarity;
  }

  /// Calculer la rotation totale (magnitude)
  static double _calculateTotalRotation(List<GyroscopeReading> readings) {
    if (readings.isEmpty) return 0.0;
    
    double totalRotation = 0.0;
    for (final reading in readings) {
      final magnitude = sqrt(reading.x * reading.x + reading.y * reading.y + reading.z * reading.z);
      totalRotation += magnitude;
    }
    
    return totalRotation / readings.length;
  }

  /// NOUVELLE APPROCHE : Utiliser directement les données accéléromètre comme mouvement
  static List<Point3D> _extractTrajectory(List<AccelerometerReading> readings) {
    if (readings.isEmpty) return [];

    print('🔧 Extraction trajectoire depuis ${readings.length} points accelerometer');

    // APPROCHE DIRECTE : Accumulation des mouvements sans intégration foireuse
    final trajectory = <Point3D>[];
    
    // Calculer la gravité moyenne pour la soustraire
    double avgGravX = 0, avgGravY = 0, avgGravZ = 0;
    for (final reading in readings) {
      avgGravX += reading.x;
      avgGravY += reading.y; 
      avgGravZ += reading.z;
    }
    avgGravX /= readings.length;
    avgGravY /= readings.length;
    avgGravZ /= readings.length;
    
    print('🌍 Gravité moyenne détectée: X:${avgGravX.toStringAsFixed(2)} Y:${avgGravY.toStringAsFixed(2)} Z:${avgGravZ.toStringAsFixed(2)}');

    // Construire la trajectoire en accumulant les mouvements significatifs
    double cumX = 0, cumY = 0, cumZ = 0;
    
    for (int i = 0; i < readings.length; i++) {
      final reading = readings[i];
      
      // Soustraire la gravité statique
      final movementX = reading.x - avgGravX;
      final movementY = reading.y - avgGravY;
      final movementZ = reading.z - avgGravZ;
      
      // Filtrer les petits mouvements (bruit)
      const double NOISE_THRESHOLD = 0.5;
      
      if (movementX.abs() > NOISE_THRESHOLD) cumX += movementX * 0.1;
      if (movementY.abs() > NOISE_THRESHOLD) cumY += movementY * 0.1;  
      if (movementZ.abs() > NOISE_THRESHOLD) cumZ += movementZ * 0.1;
      
      trajectory.add(Point3D(cumX, cumY, cumZ));
    }

    print('🎯 Trajectoire extraite: ${trajectory.length} points');
    if (trajectory.isNotEmpty) {
      final first = trajectory.first;
      final last = trajectory.last;
      print('🎯 Début: (${first.x.toStringAsFixed(2)}, ${first.y.toStringAsFixed(2)}, ${first.z.toStringAsFixed(2)})');
      print('🎯 Fin: (${last.x.toStringAsFixed(2)}, ${last.y.toStringAsFixed(2)}, ${last.z.toStringAsFixed(2)})');
    }

    return trajectory;
  }

  /// Normaliser une trajectoire (centrer, dimensionner)
  static List<Point3D> _normalizeTrajectory(List<Point3D> trajectory) {
    if (trajectory.length < 2) return trajectory;

    // 1. Centrer la trajectoire
    double centerX = 0, centerY = 0, centerZ = 0;
    for (final point in trajectory) {
      centerX += point.x;
      centerY += point.y;
      centerZ += point.z;
    }
    centerX /= trajectory.length;
    centerY /= trajectory.length;
    centerZ /= trajectory.length;

    // 2. Calculer l'étendue
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    double minZ = double.infinity, maxZ = double.negativeInfinity;

    final centered = <Point3D>[];
    for (final point in trajectory) {
      final centeredPoint = Point3D(
        point.x - centerX,
        point.y - centerY,
        point.z - centerZ,
      );
      centered.add(centeredPoint);

      minX = min(minX, centeredPoint.x);
      maxX = max(maxX, centeredPoint.x);
      minY = min(minY, centeredPoint.y);
      maxY = max(maxY, centeredPoint.y);
      minZ = min(minZ, centeredPoint.z);
      maxZ = max(maxZ, centeredPoint.z);
    }

    // 3. Normaliser à une taille standard
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final rangeZ = maxZ - minZ;
    final maxRange = max(max(rangeX, rangeY), rangeZ);

    if (maxRange == 0) return centered;

    final normalized = <Point3D>[];
    for (final point in centered) {
      normalized.add(Point3D(
        point.x / maxRange,
        point.y / maxRange,
        point.z / maxRange,
      ));
    }

    return normalized;
  }

  /// PLUS DE SIMPLIFICATION DÉBILE ! On garde TOUS les points !
  static List<Point3D> _simplifyTrajectory(List<Point3D> trajectory) {
    // FINI la simplification qui détruit tout ! On garde la richesse des capteurs !
    print('🔍 Simplification désactivée - on garde ${trajectory.length} points intacts');
    return List.from(trajectory); // Copie sans modification
  }

  /// Distance d'un point à une ligne (version 3D simplifiée)
  static double _pointToLineDistance(Point3D point, Point3D lineStart, Point3D lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;
    final dz = lineEnd.z - lineStart.z;

    final lineLength = sqrt(dx * dx + dy * dy + dz * dz);
    if (lineLength == 0) return _distance3D(point, lineStart);

    final t = max(0.0, min(1.0, 
      ((point.x - lineStart.x) * dx + 
       (point.y - lineStart.y) * dy + 
       (point.z - lineStart.z) * dz) / (lineLength * lineLength)));

    final projectionX = lineStart.x + t * dx;
    final projectionY = lineStart.y + t * dy;
    final projectionZ = lineStart.z + t * dz;

    final distX = point.x - projectionX;
    final distY = point.y - projectionY;
    final distZ = point.z - projectionZ;

    return sqrt(distX * distX + distY * distY + distZ * distZ);
  }

  /// Distance 3D entre deux points
  static double _distance3D(Point3D p1, Point3D p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    final dz = p1.z - p2.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Détecter le pattern d'une trajectoire
  static GesturePattern _detectPattern(List<Point3D> trajectory) {
    if (trajectory.length < 2) {
      return GesturePattern(type: 'unknown', confidence: 0.0, features: {});
    }

    // Tests de patterns basiques (ordre d'importance - formes spécifiques d'abord)
    final patterns = <GesturePattern>[
      _detectCircle(trajectory),
      _detectZigZag(trajectory),
      _detectWave(trajectory),
      _detectLine(trajectory), // Ligne en dernier car trop générique
    ];

    // Retourner le pattern avec la meilleure confiance
    patterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    return patterns.first;
  }

  /// Détecter un pattern de ligne droite
  static GesturePattern _detectLine(List<Point3D> trajectory) {
    if (trajectory.length < 2) {
      return GesturePattern(type: 'line', confidence: 0.0, features: {});
    }

    final start = trajectory.first;
    final end = trajectory.last;
    
    // Calculer la déviation moyenne par rapport à la ligne droite
    double totalDeviation = 0.0;
    for (final point in trajectory) {
      totalDeviation += _pointToLineDistance(point, start, end);
    }
    final avgDeviation = totalDeviation / trajectory.length;
    
    // Plus la déviation est faible, plus c'est une ligne - plus strict maintenant
    final confidence = max(0.0, 1.0 - (avgDeviation * 25)); // Plus strict pour éviter faux positifs
    
    return GesturePattern(
      type: 'line',
      confidence: confidence,
      features: {
        'length': _distance3D(start, end),
        'avgDeviation': avgDeviation,
      },
    );
  }

  /// Détecter un pattern de cercle
  static GesturePattern _detectCircle(List<Point3D> trajectory) {
    if (trajectory.length < 8) { // Plus de points requis pour un cercle
      return GesturePattern(type: 'circle', confidence: 0.0, features: {});
    }

    // 1. Vérifier si on revient près du point de départ
    final start = trajectory.first;
    final end = trajectory.last;
    final closureDistance = _distance3D(start, end);
    
    // 2. Calculer le rayon moyen depuis le centre estimé
    double centerX = 0, centerY = 0, centerZ = 0;
    for (final point in trajectory) {
      centerX += point.x;
      centerY += point.y;
      centerZ += point.z;
    }
    centerX /= trajectory.length;
    centerY /= trajectory.length;
    centerZ /= trajectory.length;
    
    final center = Point3D(centerX, centerY, centerZ);
    
    // 3. Calculer la variance des distances au centre
    double sumDistances = 0.0;
    for (final point in trajectory) {
      sumDistances += _distance3D(point, center);
    }
    final avgRadius = sumDistances / trajectory.length;
    
    double variance = 0.0;
    for (final point in trajectory) {
      final distance = _distance3D(point, center);
      variance += pow(distance - avgRadius, 2);
    }
    variance /= trajectory.length;
    
    // Plus la variance est faible et plus on ferme la boucle, plus c'est un cercle
    final radiusConsistency = max(0.0, 1.0 - (sqrt(variance) / avgRadius));
    final closure = max(0.0, 1.0 - (closureDistance * 3)); // Plus tolérant sur la fermeture
    
    // Bonus si le mouvement couvre un angle significatif (pas juste une ligne)
    final anglesCovered = _calculateAnglesCovered(trajectory, center);
    final angleCoverage = min(1.0, anglesCovered / (1.5 * pi)); // ~270° pour confiance max
    
    final confidence = (radiusConsistency * 0.4 + closure * 0.3 + angleCoverage * 0.3).clamp(0.0, 1.0);
    
    return GesturePattern(
      type: 'circle',
      confidence: confidence,
      features: {
        'radius': avgRadius,
        'closure': closureDistance,
        'variance': variance,
        'angleCoverage': angleCoverage,
      },
    );
  }

  /// Calculer l'angle total couvert par la trajectoire autour du centre
  static double _calculateAnglesCovered(List<Point3D> trajectory, Point3D center) {
    if (trajectory.length < 3) return 0.0;
    
    final angles = <double>[];
    for (final point in trajectory) {
      final dx = point.x - center.x;
      final dy = point.y - center.y;
      if (dx != 0 || dy != 0) {
        angles.add(atan2(dy, dx));
      }
    }
    
    if (angles.length < 3) return 0.0;
    
    // Calculer l'angle total parcouru
    double totalAngle = 0.0;
    for (int i = 1; i < angles.length; i++) {
      double angleDiff = angles[i] - angles[i - 1];
      
      // Normaliser la différence d'angle
      while (angleDiff > pi) angleDiff -= 2 * pi;
      while (angleDiff < -pi) angleDiff += 2 * pi;
      
      totalAngle += angleDiff.abs();
    }
    
    return totalAngle;
  }

  /// Détecter un pattern de zigzag (Z)
  static GesturePattern _detectZigZag(List<Point3D> trajectory) {
    if (trajectory.length < 4) {
      return GesturePattern(type: 'zigzag', confidence: 0.0, features: {});
    }

    // Détecter les changements de direction significatifs
    final directions = <double>[];
    for (int i = 1; i < trajectory.length; i++) {
      final prev = trajectory[i - 1];
      final current = trajectory[i];
      
      final dx = current.x - prev.x;
      final dy = current.y - prev.y;
      
      if (dx != 0 || dy != 0) {
        directions.add(atan2(dy, dx));
      }
    }

    if (directions.length < 3) {
      return GesturePattern(type: 'zigzag', confidence: 0.0, features: {});
    }

    // Compter les changements de direction significatifs
    int directionChanges = 0;
    const double DIRECTION_THRESHOLD = pi / 4; // 45 degrés

    for (int i = 1; i < directions.length; i++) {
      double angleDiff = (directions[i] - directions[i - 1]).abs();
      if (angleDiff > pi) angleDiff = 2 * pi - angleDiff; // Normaliser
      
      if (angleDiff > DIRECTION_THRESHOLD) {
        directionChanges++;
      }
    }

    // Un zigzag a typiquement 2-4 changements de direction
    final confidence = directionChanges >= 2 ? 
      min(1.0, directionChanges / 4.0) : 0.0;

    return GesturePattern(
      type: 'zigzag',
      confidence: confidence,
      features: {
        'directionChanges': directionChanges.toDouble(),
        'totalDirections': directions.length.toDouble(),
      },
    );
  }

  /// Détecter un pattern de vague
  static GesturePattern _detectWave(List<Point3D> trajectory) {
    if (trajectory.length < 6) {
      return GesturePattern(type: 'wave', confidence: 0.0, features: {});
    }

    // Analyser les oscillations dans une direction principale
    // Simplification: projection sur plan XY
    final yValues = trajectory.map((p) => p.y).toList();
    
    // Détecter les pics et creux
    int peaks = 0;
    int valleys = 0;
    
    for (int i = 1; i < yValues.length - 1; i++) {
      if (yValues[i] > yValues[i - 1] && yValues[i] > yValues[i + 1]) {
        peaks++;
      }
      if (yValues[i] < yValues[i - 1] && yValues[i] < yValues[i + 1]) {
        valleys++;
      }
    }

    // Une vague a des oscillations régulières
    final totalOscillations = peaks + valleys;
    final confidence = totalOscillations >= 2 ? 
      min(1.0, totalOscillations / 6.0) : 0.0;

    return GesturePattern(
      type: 'wave',
      confidence: confidence,
      features: {
        'peaks': peaks.toDouble(),
        'valleys': valleys.toDouble(),
        'oscillations': totalOscillations.toDouble(),
      },
    );
  }

  /// Comparer deux patterns
  static double _comparePatterns(GesturePattern pattern1, GesturePattern pattern2) {
    // Si types différents, similarité faible
    if (pattern1.type != pattern2.type) {
      return 0.1; // Petite chance de match sur type différent
    }

    // Si même type, combiner les confidences et features
    final avgConfidence = (pattern1.confidence + pattern2.confidence) / 2;
    
    // Bonus si les deux ont une forte confiance
    final confidenceBonus = min(pattern1.confidence, pattern2.confidence);
    
    return (avgConfidence * 0.7 + confidenceBonus * 0.3).clamp(0.0, 1.0);
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
    _realtimeAnalysisTimer?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _realtimeAnalysisTimer = null;
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

  @override
  String toString() => 'Point3D($x, $y, $z)';
}

/// Classe pour représenter un pattern détecté
class GesturePattern {
  final String type;
  final double confidence;
  final Map<String, double> features;

  const GesturePattern({
    required this.type,
    required this.confidence,
    required this.features,
  });

  @override
  String toString() => 'Pattern($type, ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Classe pour représenter la direction d'un mouvement
class MovementDirection {
  final String type; // 'clockwise', 'counterclockwise', 'linear', 'complex', 'unknown'
  final double confidence;
  final Map<String, double> features;

  const MovementDirection({
    required this.type,
    required this.confidence,
    this.features = const {},
  });

  @override
  String toString() => 'Direction($type, ${(confidence * 100).toStringAsFixed(1)}%)';
} 