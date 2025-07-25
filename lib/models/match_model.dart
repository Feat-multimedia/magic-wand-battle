import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { pending, inProgress, finished }

class MatchModel {
  final String id;
  final DocumentReference arenaId;
  final DocumentReference player1;
  final DocumentReference player2;
  final DocumentReference? winner;
  final MatchStatus status;
  final int roundsToWin;
  final DateTime createdAt;

  MatchModel({
    required this.id,
    required this.arenaId,
    required this.player1,
    required this.player2,
    this.winner,
    required this.status,
    required this.roundsToWin,
    required this.createdAt,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return MatchModel(
      id: doc.id,
      arenaId: data['arenaId'] as DocumentReference,
      player1: data['player1'] as DocumentReference,
      player2: data['player2'] as DocumentReference,
      winner: data['winner'] as DocumentReference?,
      status: _parseMatchStatus(data['status']),
      roundsToWin: data['roundsToWin'] ?? 3,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'arenaId': arenaId,
      'player1': player1,
      'player2': player2,
      'winner': winner,
      'status': status.toString().split('.').last,
      'roundsToWin': roundsToWin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static MatchStatus _parseMatchStatus(dynamic value) {
    if (value == null) return MatchStatus.pending;
    switch (value.toString()) {
      case 'pending':
        return MatchStatus.pending;
      case 'inProgress':
        return MatchStatus.inProgress;
      case 'finished':
        return MatchStatus.finished;
      default:
        return MatchStatus.pending;
    }
  }

  MatchModel copyWith({
    String? id,
    DocumentReference? arenaId,
    DocumentReference? player1,
    DocumentReference? player2,
    DocumentReference? winner,
    MatchStatus? status,
    int? roundsToWin,
    DateTime? createdAt,
  }) {
    return MatchModel(
      id: id ?? this.id,
      arenaId: arenaId ?? this.arenaId,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      winner: winner ?? this.winner,
      status: status ?? this.status,
      roundsToWin: roundsToWin ?? this.roundsToWin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isFinished => status == MatchStatus.finished;
  bool get isInProgress => status == MatchStatus.inProgress;
  bool get isPending => status == MatchStatus.pending;
} 