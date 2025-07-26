import 'package:cloud_firestore/cloud_firestore.dart';
import 'tournament_model.dart';

/// 🎯 **Types de matches dans un bracket**
enum BracketMatchType {
  qualification, // Match de qualification
  elimination,   // Match d'élimination
  semifinal,     // Demi-finale
  final_,        // Finale
  consolation,   // Match de consolation (3ème place)
}

/// 📊 **Statut d'un match de bracket**
enum BracketMatchStatus {
  pending,    // En attente
  ready,      // Prêt (joueurs confirmés)
  inProgress, // En cours
  completed,  // Terminé
  forfeit,    // Forfait
}

/// ⚔️ **Match dans un bracket de tournoi**
class BracketMatch {
  final String id;
  final String tournamentId;
  final int round; // 1, 2, 3... (1 = premier tour)
  final int position; // Position dans le round
  final BracketMatchType type;
  final BracketMatchStatus status;
  
  // 👥 Participants
  final String? player1Id;
  final String? player2Id;
  final String? winnerId;
  final String? loserId;
  
  // 📊 Résultats
  final double? player1Score;
  final double? player2Score;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  
  // 🔗 Liens dans le bracket
  final String? nextMatchId; // Match suivant pour le gagnant
  final String? loserNextMatchId; // Match suivant pour le perdant (double élimination)
  final List<String> previousMatchIds; // Matches précédents qui alimentent celui-ci
  
  // 📝 Métadonnées
  final Map<String, dynamic> metadata;

  const BracketMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.position,
    required this.type,
    required this.status,
    this.player1Id,
    this.player2Id,
    this.winnerId,
    this.loserId,
    this.player1Score,
    this.player2Score,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.nextMatchId,
    this.loserNextMatchId,
    this.previousMatchIds = const [],
    this.metadata = const {},
  });

  factory BracketMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BracketMatch(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      round: data['round'] ?? 1,
      position: data['position'] ?? 0,
      type: BracketMatchType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => BracketMatchType.elimination,
      ),
      status: BracketMatchStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => BracketMatchStatus.pending,
      ),
      player1Id: data['player1Id'],
      player2Id: data['player2Id'],
      winnerId: data['winnerId'],
      loserId: data['loserId'],
      player1Score: data['player1Score']?.toDouble(),
      player2Score: data['player2Score']?.toDouble(),
      scheduledAt: data['scheduledAt'] != null 
        ? (data['scheduledAt'] as Timestamp).toDate() 
        : null,
      startedAt: data['startedAt'] != null 
        ? (data['startedAt'] as Timestamp).toDate() 
        : null,
      completedAt: data['completedAt'] != null 
        ? (data['completedAt'] as Timestamp).toDate() 
        : null,
      nextMatchId: data['nextMatchId'],
      loserNextMatchId: data['loserNextMatchId'],
      previousMatchIds: List<String>.from(data['previousMatchIds'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tournamentId': tournamentId,
      'round': round,
      'position': position,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'winnerId': winnerId,
      'loserId': loserId,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'nextMatchId': nextMatchId,
      'loserNextMatchId': loserNextMatchId,
      'previousMatchIds': previousMatchIds,
      'metadata': metadata,
    };
  }

  /// 🔄 **Méthodes utilitaires**
  
  bool get isReady => player1Id != null && player2Id != null;
  bool get isCompleted => status == BracketMatchStatus.completed;
  bool get hasWinner => winnerId != null;
  
  String get displayName {
    switch (type) {
      case BracketMatchType.final_:
        return 'Finale';
      case BracketMatchType.semifinal:
        return 'Demi-finale';
      case BracketMatchType.consolation:
        return '3ème place';
      default:
        return 'Round $round - Match ${position + 1}';
    }
  }
  
  BracketMatch copyWith({
    BracketMatchType? type,
    BracketMatchStatus? status,
    String? player1Id,
    String? player2Id,
    String? winnerId,
    String? loserId,
    double? player1Score,
    double? player2Score,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? nextMatchId,
    String? loserNextMatchId,
    List<String>? previousMatchIds,
    Map<String, dynamic>? metadata,
  }) {
    return BracketMatch(
      id: id,
      tournamentId: tournamentId,
      round: round,
      position: position,
      type: type ?? this.type,
      status: status ?? this.status,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      winnerId: winnerId ?? this.winnerId,
      loserId: loserId ?? this.loserId,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      nextMatchId: nextMatchId ?? this.nextMatchId,
      loserNextMatchId: loserNextMatchId ?? this.loserNextMatchId,
      previousMatchIds: previousMatchIds ?? this.previousMatchIds,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 🏆 **Structure complète du bracket**
class TournamentBracket {
  final String id;
  final String tournamentId;
  final TournamentType type;
  final List<BracketMatch> matches;
  final Map<int, List<BracketMatch>> roundMatches; // Matches organisés par round
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TournamentBracket({
    required this.id,
    required this.tournamentId,
    required this.type,
    required this.matches,
    required this.roundMatches,
    required this.createdAt,
    this.updatedAt,
  });

  factory TournamentBracket.fromMatches({
    required String id,
    required String tournamentId,
    required TournamentType type,
    required List<BracketMatch> matches,
  }) {
    // Organiser les matches par round
    final Map<int, List<BracketMatch>> roundMatches = {};
    for (final match in matches) {
      roundMatches.putIfAbsent(match.round, () => []).add(match);
    }
    
    // Trier les matches dans chaque round par position
    for (final round in roundMatches.keys) {
      roundMatches[round]!.sort((a, b) => a.position.compareTo(b.position));
    }

    return TournamentBracket(
      id: id,
      tournamentId: tournamentId,
      type: type,
      matches: matches,
      roundMatches: roundMatches,
      createdAt: DateTime.now(),
    );
  }

  /// 🔄 **Méthodes utilitaires**
  
  int get totalRounds => roundMatches.keys.isNotEmpty ? roundMatches.keys.reduce((a, b) => a > b ? a : b) : 0;
  
  List<BracketMatch> getMatchesForRound(int round) => roundMatches[round] ?? [];
  
  BracketMatch? getMatchById(String matchId) {
    try {
      return matches.firstWhere((match) => match.id == matchId);
    } catch (e) {
      return null;
    }
  }
  
  List<BracketMatch> get pendingMatches => matches.where((m) => m.status == BracketMatchStatus.pending).toList();
  List<BracketMatch> get readyMatches => matches.where((m) => m.status == BracketMatchStatus.ready).toList();
  List<BracketMatch> get completedMatches => matches.where((m) => m.status == BracketMatchStatus.completed).toList();
  
  bool get isComplete => matches.every((match) => match.isCompleted);
  
  BracketMatch? get finalMatch => matches.where((m) => m.type == BracketMatchType.final_).isNotEmpty 
    ? matches.firstWhere((m) => m.type == BracketMatchType.final_) 
    : null;
  
  String? get championId => finalMatch?.winnerId;
  
  TournamentBracket copyWith({
    List<BracketMatch>? matches,
    DateTime? updatedAt,
  }) {
    final newMatches = matches ?? this.matches;
    return TournamentBracket.fromMatches(
      id: id,
      tournamentId: tournamentId,
      type: type,
      matches: newMatches,
    );
  }
} 