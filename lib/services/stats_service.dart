import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/round_model.dart';
import '../models/user_model.dart';

import '../utils/logger.dart';

/// Classe pour les statistiques d'un joueur
class PlayerStats {
  final int totalMatches;
  final int wins;
  final int losses;
  final double winRate;
  final int totalSpellsCast;
  final double averageAccuracy;
  final double totalScore;
  final String favoriteSpell;
  final int gestureBonus;
  final DateTime? lastMatchDate;
  final List<MatchModel> recentMatches;
  final Map<String, int> spellsUsed;
  final Map<String, double> spellAccuracy;

  PlayerStats({
    this.totalMatches = 0,
    this.wins = 0,
    this.losses = 0,
    this.winRate = 0.0,
    this.totalSpellsCast = 0,
    this.averageAccuracy = 0.0,
    this.totalScore = 0.0,
    this.favoriteSpell = '',
    this.gestureBonus = 0,
    this.lastMatchDate,
    this.recentMatches = const [],
    this.spellsUsed = const {},
    this.spellAccuracy = const {},
  });

  PlayerStats copyWith({
    int? totalMatches,
    int? wins,
    int? losses,
    double? winRate,
    int? totalSpellsCast,
    double? averageAccuracy,
    double? totalScore,
    String? favoriteSpell,
    int? gestureBonus,
    DateTime? lastMatchDate,
    List<MatchModel>? recentMatches,
    Map<String, int>? spellsUsed,
    Map<String, double>? spellAccuracy,
  }) {
    return PlayerStats(
      totalMatches: totalMatches ?? this.totalMatches,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      winRate: winRate ?? this.winRate,
      totalSpellsCast: totalSpellsCast ?? this.totalSpellsCast,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      totalScore: totalScore ?? this.totalScore,
      favoriteSpell: favoriteSpell ?? this.favoriteSpell,
      gestureBonus: gestureBonus ?? this.gestureBonus,
      lastMatchDate: lastMatchDate ?? this.lastMatchDate,
      recentMatches: recentMatches ?? this.recentMatches,
      spellsUsed: spellsUsed ?? this.spellsUsed,
      spellAccuracy: spellAccuracy ?? this.spellAccuracy,
    );
  }

  /// Obtenir le niveau du joueur basé sur le nombre de matchs
  String get playerLevel {
    if (totalMatches < 5) return 'Apprenti Sorcier';
    if (totalMatches < 15) return 'Sorcier Novice';
    if (totalMatches < 30) return 'Sorcier Expérimenté';
    if (totalMatches < 50) return 'Maître Sorcier';
    return 'Grand Maître';
  }

  /// Obtenir la couleur du niveau
  String get levelColor {
    if (totalMatches < 5) return '#6B7280'; // Gris
    if (totalMatches < 15) return '#10B981'; // Vert
    if (totalMatches < 30) return '#3B82F6'; // Bleu
    if (totalMatches < 50) return '#8B5CF6'; // Violet
    return '#F59E0B'; // Or
  }
}

/// Service pour calculer les statistiques des joueurs
class StatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculer toutes les statistiques d'un joueur
  static Future<PlayerStats> getPlayerStats(String playerId) async {
    try {
      // 1. Récupérer tous les matchs du joueur
      final matches = await _getPlayerMatches(playerId);
      
      // 2. Récupérer tous les rounds du joueur
      final rounds = await _getPlayerRounds(playerId);
      
      // 3. Calculer les statistiques
      final stats = _calculateStats(playerId, matches, rounds);
      
      return stats;
    } catch (e) {
      Logger.error(' Erreur calcul statistiques: $e');
      return PlayerStats();
    }
  }

  /// Récupérer tous les matchs d'un joueur (terminés uniquement)
  static Future<List<MatchModel>> _getPlayerMatches(String playerId) async {
    final userRef = _firestore.collection('users').doc(playerId);
    
    final matchesSnapshot = await _firestore
        .collection('matches')
        .where('status', isEqualTo: MatchStatus.finished.name)
        .get();

    final matches = <MatchModel>[];
    
    for (final doc in matchesSnapshot.docs) {
      final match = MatchModel.fromFirestore(doc);
      
      // Vérifier si le joueur participe à ce match
      if (match.player1.id == playerId || match.player2.id == playerId) {
        matches.add(match);
      }
    }

    // Trier par date (plus récent en premier)
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return matches;
  }

  /// Récupérer tous les rounds d'un joueur
  static Future<List<RoundModel>> _getPlayerRounds(String playerId) async {
    final userRef = _firestore.collection('users').doc(playerId);
    
    final roundsSnapshot = await _firestore
        .collection('rounds')
        .where('playerId', isEqualTo: userRef)
        .orderBy('timestamp', descending: true)
        .get();

    return roundsSnapshot.docs
        .map((doc) => RoundModel.fromFirestore(doc))
        .toList();
  }

  /// Calculer les statistiques à partir des matchs et rounds
  static PlayerStats _calculateStats(
    String playerId,
    List<MatchModel> matches,
    List<RoundModel> rounds,
  ) {
    // Statistiques de base
    final totalMatches = matches.length;
    int wins = 0;
    int losses = 0;

    // Compter victoires/défaites
    for (final match in matches) {
      if (match.winner?.id == playerId) {
        wins++;
      } else if (match.winner != null) {
        losses++;
      }
    }

    final winRate = totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;

    // Statistiques des sorts
    final totalSpellsCast = rounds.length;
    final totalScore = rounds.fold<double>(0.0, (sum, round) => sum + round.totalScore);
    final averageAccuracy = rounds.isNotEmpty 
        ? rounds.fold<double>(0.0, (sum, round) => sum + round.gestureAccuracy) / rounds.length
        : 0.0;

    // Compter les bonus gestuels
    final gestureBonus = rounds.where((round) => round.voiceBonus).length;

    // Analyser les sorts utilisés
    final Map<String, int> spellsUsed = {};
    final Map<String, List<double>> spellAccuracyMap = {};

    for (final round in rounds) {
      final spell = round.spellCast;
      spellsUsed[spell] = (spellsUsed[spell] ?? 0) + 1;
      
      if (!spellAccuracyMap.containsKey(spell)) {
        spellAccuracyMap[spell] = [];
      }
      spellAccuracyMap[spell]!.add(round.gestureAccuracy);
    }

    // Calculer la précision moyenne par sort
    final Map<String, double> spellAccuracy = {};
    spellAccuracyMap.forEach((spell, accuracies) {
      spellAccuracy[spell] = accuracies.fold<double>(0.0, (sum, acc) => sum + acc) / accuracies.length;
    });

    // Sort favori (le plus utilisé)
    String favoriteSpell = '';
    int maxUsage = 0;
    spellsUsed.forEach((spell, count) {
      if (count > maxUsage) {
        maxUsage = count;
        favoriteSpell = spell;
      }
    });

    // Date du dernier match
    final lastMatchDate = matches.isNotEmpty ? matches.first.createdAt : null;

    // Matchs récents (5 derniers)
    final recentMatches = matches.take(5).toList();

    return PlayerStats(
      totalMatches: totalMatches,
      wins: wins,
      losses: losses,
      winRate: winRate,
      totalSpellsCast: totalSpellsCast,
      averageAccuracy: averageAccuracy,
      totalScore: totalScore,
      favoriteSpell: favoriteSpell,
      gestureBonus: gestureBonus,
      lastMatchDate: lastMatchDate,
      recentMatches: recentMatches,
      spellsUsed: spellsUsed,
      spellAccuracy: spellAccuracy,
    );
  }

  /// Obtenir le classement global des joueurs
  static Future<List<PlayerRanking>> getGlobalRanking({int limit = 10}) async {
    try {
      // Récupérer tous les utilisateurs
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      // Calculer les stats pour chaque joueur
      final List<PlayerRanking> rankings = [];
      
      for (final user in users) {
        final stats = await getPlayerStats(user.id);
        rankings.add(PlayerRanking(
          user: user,
          stats: stats,
          score: _calculateRankingScore(stats),
        ));
      }

      // Trier par score
      rankings.sort((a, b) => b.score.compareTo(a.score));

      return rankings.take(limit).toList();
    } catch (e) {
      Logger.error(' Erreur calcul classement: $e');
      return [];
    }
  }

  /// Calculer le score de classement d'un joueur
  static double _calculateRankingScore(PlayerStats stats) {
    // Formule de score : victoires * 3 + précision moyenne + bonus gestuels * 0.1
    return (stats.wins * 3.0) + stats.averageAccuracy + (stats.gestureBonus * 0.1);
  }

  // 🔧 MÉTHODES POUR L'ADMIN DASHBOARD

  /// Obtenir le nombre total d'utilisateurs
  static Future<int> getUsersCount() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir le nombre total de sorts
  static Future<int> getSpellsCount() async {
    try {
      final snapshot = await _firestore.collection('spells').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir le nombre total d'arènes
  static Future<int> getArenasCount() async {
    try {
      final snapshot = await _firestore.collection('arenas').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir le nombre total de matchs
  static Future<int> getMatchesCount() async {
    try {
      final snapshot = await _firestore.collection('matches').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir toutes les statistiques d'un coup pour l'admin
  static Future<Map<String, int>> getAllStats() async {
    try {
      final results = await Future.wait([
        getUsersCount(),
        getSpellsCount(),
        getArenasCount(),
        getMatchesCount(),
      ]);

      return {
        'users': results[0],
        'spells': results[1],
        'arenas': results[2],
        'matches': results[3],
      };
    } catch (e) {
      return {
        'users': 0,
        'spells': 0,
        'arenas': 0,
        'matches': 0,
      };
    }
  }
}

/// Classe pour le classement des joueurs
class PlayerRanking {
  final UserModel user;
  final PlayerStats stats;
  final double score;

  PlayerRanking({
    required this.user,
    required this.stats,
    required this.score,
  });
} 