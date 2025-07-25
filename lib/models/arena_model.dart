import 'package:cloud_firestore/cloud_firestore.dart';

enum ArenaType { exhibition, tournament }

enum ArenaStatus { waiting, inProgress, finished }

class ArenaModel {
  final String id;
  final String title;
  final ArenaType type;
  final ArenaStatus status;
  final DocumentReference createdBy;
  final int maxRounds;
  final List<DocumentReference> players;
  final DateTime createdAt;

  ArenaModel({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.createdBy,
    required this.maxRounds,
    required this.players,
    required this.createdAt,
  });

  factory ArenaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ArenaModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: _parseArenaType(data['type']),
      status: _parseArenaStatus(data['status']),
      createdBy: data['createdBy'] as DocumentReference,
      maxRounds: data['maxRounds'] ?? 3,
      players: List<DocumentReference>.from(data['players'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdBy': createdBy,
      'maxRounds': maxRounds,
      'players': players,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ArenaType _parseArenaType(dynamic value) {
    if (value == null) return ArenaType.exhibition;
    switch (value.toString()) {
      case 'exhibition':
        return ArenaType.exhibition;
      case 'tournament':
        return ArenaType.tournament;
      default:
        return ArenaType.exhibition;
    }
  }

  static ArenaStatus _parseArenaStatus(dynamic value) {
    if (value == null) return ArenaStatus.waiting;
    switch (value.toString()) {
      case 'waiting':
        return ArenaStatus.waiting;
      case 'inProgress':
        return ArenaStatus.inProgress;
      case 'finished':
        return ArenaStatus.finished;
      default:
        return ArenaStatus.waiting;
    }
  }

  ArenaModel copyWith({
    String? id,
    String? title,
    ArenaType? type,
    ArenaStatus? status,
    DocumentReference? createdBy,
    int? maxRounds,
    List<DocumentReference>? players,
    DateTime? createdAt,
  }) {
    return ArenaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      maxRounds: maxRounds ?? this.maxRounds,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isFull => players.length >= 2;
  bool get canStart => players.length == 2 && status == ArenaStatus.waiting;
} 