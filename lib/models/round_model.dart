import 'package:cloud_firestore/cloud_firestore.dart';

class RoundModel {
  final String id;
  final int index;
  final String player1Spell;
  final String player2Spell;
  final String? player1Voice;
  final String? player2Voice;
  final double player1Bonus;
  final double player2Bonus;
  final DocumentReference? winner;
  final DateTime timestamp;

  RoundModel({
    required this.id,
    required this.index,
    required this.player1Spell,
    required this.player2Spell,
    this.player1Voice,
    this.player2Voice,
    required this.player1Bonus,
    required this.player2Bonus,
    this.winner,
    required this.timestamp,
  });

  factory RoundModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RoundModel(
      id: doc.id,
      index: data['index'] ?? 0,
      player1Spell: data['player1Spell'] ?? '',
      player2Spell: data['player2Spell'] ?? '',
      player1Voice: data['player1Voice'],
      player2Voice: data['player2Voice'],
      player1Bonus: (data['player1Bonus'] ?? 0.0).toDouble(),
      player2Bonus: (data['player2Bonus'] ?? 0.0).toDouble(),
      winner: data['winner'] as DocumentReference?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'index': index,
      'player1Spell': player1Spell,
      'player2Spell': player2Spell,
      'player1Voice': player1Voice,
      'player2Voice': player2Voice,
      'player1Bonus': player1Bonus,
      'player2Bonus': player2Bonus,
      'winner': winner,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  RoundModel copyWith({
    String? id,
    int? index,
    String? player1Spell,
    String? player2Spell,
    String? player1Voice,
    String? player2Voice,
    double? player1Bonus,
    double? player2Bonus,
    DocumentReference? winner,
    DateTime? timestamp,
  }) {
    return RoundModel(
      id: id ?? this.id,
      index: index ?? this.index,
      player1Spell: player1Spell ?? this.player1Spell,
      player2Spell: player2Spell ?? this.player2Spell,
      player1Voice: player1Voice ?? this.player1Voice,
      player2Voice: player2Voice ?? this.player2Voice,
      player1Bonus: player1Bonus ?? this.player1Bonus,
      player2Bonus: player2Bonus ?? this.player2Bonus,
      winner: winner ?? this.winner,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  double get player1TotalPoints => 1.0 + player1Bonus;
  double get player2TotalPoints => 1.0 + player2Bonus;
  
  bool get isDraw => winner == null;
  bool get hasWinner => winner != null;
  
  bool get player1HasVoiceBonus => player1Voice != null && player1Voice!.isNotEmpty;
  bool get player2HasVoiceBonus => player2Voice != null && player2Voice!.isNotEmpty;
} 