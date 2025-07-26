import 'package:cloud_firestore/cloud_firestore.dart';

class SpellModel {
  final String id;
  final String name;
  final GestureData gestureData;
  final String voiceKeyword;
  final String beats; // ID du sort que ce sort bat
  final String? soundFileUrl; // 🆕 URL du fichier son uploadé
  final DateTime createdAt;

  SpellModel({
    required this.id,
    required this.name,
    required this.gestureData,
    required this.voiceKeyword,
    required this.beats,
    this.soundFileUrl,
    required this.createdAt,
  });

  factory SpellModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return SpellModel(
      id: doc.id,
      name: data['name'] ?? '',
      gestureData: GestureData.fromMap(data['gestureData'] ?? {}),
      voiceKeyword: data['voiceKeyword'] ?? '',
      beats: data['beats'] ?? '',
      soundFileUrl: data['soundFileUrl'], // URL du son uploadé
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'gestureData': gestureData.toMap(),
      'voiceKeyword': voiceKeyword,
      'beats': beats,
      'soundFileUrl': soundFileUrl, // URL du son uploadé
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SpellModel copyWith({
    String? id,
    String? name,
    GestureData? gestureData,
    String? voiceKeyword,
    String? beats,
    String? soundFileUrl,
    DateTime? createdAt,
  }) {
    return SpellModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gestureData: gestureData ?? this.gestureData,
      voiceKeyword: voiceKeyword ?? this.voiceKeyword,
      beats: beats ?? this.beats,
      soundFileUrl: soundFileUrl ?? this.soundFileUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GestureData {
  final List<AccelerometerReading> accelerometerReadings;
  final List<GyroscopeReading> gyroscopeReadings;
  final double threshold;
  final int duration; // en millisecondes

  GestureData({
    required this.accelerometerReadings,
    required this.gyroscopeReadings,
    required this.threshold,
    required this.duration,
  });

  factory GestureData.fromMap(Map<String, dynamic> data) {
    return GestureData(
      accelerometerReadings: (data['accelerometerReadings'] as List<dynamic>? ?? [])
          .map((reading) => AccelerometerReading.fromMap(reading))
          .toList(),
      gyroscopeReadings: (data['gyroscopeReadings'] as List<dynamic>? ?? [])
          .map((reading) => GyroscopeReading.fromMap(reading))
          .toList(),
      threshold: (data['threshold'] ?? 0.0).toDouble(),
      duration: data['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accelerometerReadings': accelerometerReadings.map((reading) => reading.toMap()).toList(),
      'gyroscopeReadings': gyroscopeReadings.map((reading) => reading.toMap()).toList(),
      'threshold': threshold,
      'duration': duration,
    };
  }
}

class AccelerometerReading {
  final double x;
  final double y;
  final double z;
  final int timestamp;

  AccelerometerReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  factory AccelerometerReading.fromMap(Map<String, dynamic> data) {
    return AccelerometerReading(
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      z: (data['z'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp,
    };
  }
}

class GyroscopeReading {
  final double x;
  final double y;
  final double z;
  final int timestamp;

  GyroscopeReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  factory GyroscopeReading.fromMap(Map<String, dynamic> data) {
    return GyroscopeReading(
      x: (data['x'] ?? 0.0).toDouble(),
      y: (data['y'] ?? 0.0).toDouble(),
      z: (data['z'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp,
    };
  }
} 