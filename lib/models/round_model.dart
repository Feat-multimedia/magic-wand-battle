import 'package:cloud_firestore/cloud_firestore.dart';

class RoundModel {
  final String id;
  final DocumentReference matchId;
  final DocumentReference playerId;
  final String spellCast;
  final double gestureAccuracy;
  final bool voiceBonus;
  final double totalScore;
  final DateTime timestamp;

  RoundModel({
    required this.id,
    required this.matchId,
    required this.playerId,
    required this.spellCast,
    required this.gestureAccuracy,
    required this.voiceBonus,
    required this.totalScore,
    required this.timestamp,
  });

  factory RoundModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RoundModel(
      id: doc.id,
      matchId: data['matchId'] as DocumentReference,
      playerId: data['playerId'] as DocumentReference,
      spellCast: data['spellCast'] ?? '',
      gestureAccuracy: (data['gestureAccuracy'] ?? 0.0).toDouble(),
      voiceBonus: data['voiceBonus'] ?? false,
      totalScore: (data['totalScore'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'playerId': playerId,
      'spellCast': spellCast,
      'gestureAccuracy': gestureAccuracy,
      'voiceBonus': voiceBonus,
      'totalScore': totalScore,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  RoundModel copyWith({
    String? id,
    DocumentReference? matchId,
    DocumentReference? playerId,
    String? spellCast,
    double? gestureAccuracy,
    bool? voiceBonus,
    double? totalScore,
    DateTime? timestamp,
  }) {
    return RoundModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      spellCast: spellCast ?? this.spellCast,
      gestureAccuracy: gestureAccuracy ?? this.gestureAccuracy,
      voiceBonus: voiceBonus ?? this.voiceBonus,
      totalScore: totalScore ?? this.totalScore,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Calculer le score total basé sur l'exactitude du geste et le bonus vocal
  static double calculateScore(double gestureAccuracy, bool voiceBonus) {
    double baseScore = 1.0; // Score de base pour un sort réussi
    double gestureBonus = voiceBonus ? 0.5 : 0.0; // Bonus gestuel (ex-vocal)
    
    return baseScore + gestureBonus;
  }

  /// Créer un round depuis les résultats du duel
  static RoundModel fromDuelResult({
    required String matchId,
    required String playerId,
    required String spellCast,
    required double gestureAccuracy,
    required bool gestureBonus,
  }) {
    final totalScore = calculateScore(gestureAccuracy, gestureBonus);
    
    return RoundModel(
      id: '', // Sera généré par Firestore
      matchId: FirebaseFirestore.instance.collection('matches').doc(matchId),
      playerId: FirebaseFirestore.instance.collection('users').doc(playerId),
      spellCast: spellCast,
      gestureAccuracy: gestureAccuracy,
      voiceBonus: gestureBonus,
      totalScore: totalScore,
      timestamp: DateTime.now(),
    );
  }
} 