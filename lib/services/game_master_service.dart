import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_model.dart';
import '../models/round_model.dart';
import '../models/user_model.dart';

import '../utils/logger.dart';

/// Données en temps réel pour le Game Master
class LiveMatchData {
  final MatchModel match;
  final UserModel player1;
  final UserModel player2;
  final List<RoundModel> rounds;
  final Map<String, double> currentScores;
  final String status;
  final DateTime lastUpdate;

  LiveMatchData({
    required this.match,
    required this.player1,
    required this.player2,
    required this.rounds,
    required this.currentScores,
    required this.status,
    required this.lastUpdate,
  });

  /// Obtenir le joueur gagnant actuel
  String? get leadingPlayer {
    if (currentScores.isEmpty) return null;
    
    final sortedEntries = currentScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedEntries.length >= 2 && sortedEntries[0].value == sortedEntries[1].value) {
      return null; // Égalité
    }
    
    return sortedEntries.first.key;
  }

  /// Vérifier si le match est proche de la fin
  bool get isNearEnd {
    if (currentScores.isEmpty) return false;
    final maxScore = currentScores.values.reduce((a, b) => a > b ? a : b);
    final requiredScore = match.roundsToWin.toDouble();
    return maxScore >= (requiredScore * 0.8); // 80% du score requis
  }
}

/// Statistiques globales d'un événement
class EventStats {
  final int totalMatches;
  final int activeMatches;
  final int completedMatches;
  final int totalPlayers;
  final int totalSpellsCast;
  final double averageMatchDuration;
  final String mostUsedSpell;

  EventStats({
    this.totalMatches = 0,
    this.activeMatches = 0,
    this.completedMatches = 0,
    this.totalPlayers = 0,
    this.totalSpellsCast = 0,
    this.averageMatchDuration = 0.0,
    this.mostUsedSpell = '',
  });
}

/// Service pour le Game Master et la projection live
class GameMasterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Streams pour les données en temps réel
  static StreamController<List<LiveMatchData>>? _liveMatchesController;
  static StreamController<EventStats>? _eventStatsController;
  
  /// Stream des matchs actifs en temps réel
  static Stream<List<LiveMatchData>> getLiveMatchesStream() {
    _liveMatchesController?.close();
    _liveMatchesController = StreamController<List<LiveMatchData>>();
    
    // Écouter les changements de matchs
    _firestore
        .collection('matches')
        .where('status', whereIn: [MatchStatus.pending.name, MatchStatus.inProgress.name])
        .snapshots()
        .listen((snapshot) async {
      
      final liveMatches = <LiveMatchData>[];
      
      for (final doc in snapshot.docs) {
        try {
          final match = MatchModel.fromFirestore(doc);
          final liveData = await _buildLiveMatchData(match);
          liveMatches.add(liveData);
        } catch (e) {
          Logger.error(' Erreur construction live data: $e');
        }
      }
      
      // Trier par priorité (matchs en cours d'abord, puis par date)
      liveMatches.sort((a, b) {
        if (a.match.status != b.match.status) {
          return a.match.status == MatchStatus.inProgress ? -1 : 1;
        }
        return b.match.createdAt.compareTo(a.match.createdAt);
      });
      
      _liveMatchesController?.add(liveMatches);
    });
    
    return _liveMatchesController!.stream;
  }

  /// Stream des statistiques d'événement en temps réel
  static Stream<EventStats> getEventStatsStream() {
    _eventStatsController?.close();
    _eventStatsController = StreamController<EventStats>();
    
    // Mettre à jour les stats toutes les 10 secondes
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final stats = await _calculateEventStats();
      _eventStatsController?.add(stats);
    });
    
    // Envoyer les stats initiales
    _calculateEventStats().then((stats) {
      _eventStatsController?.add(stats);
    });
    
    return _eventStatsController!.stream;
  }

  /// Construire les données live d'un match
  static Future<LiveMatchData> _buildLiveMatchData(MatchModel match) async {
    try {
      // Charger les joueurs
      final player1Doc = await match.player1.get();
      final player2Doc = await match.player2.get();
      
      final player1 = UserModel.fromFirestore(player1Doc);
      final player2 = UserModel.fromFirestore(player2Doc);
      
      // Charger les rounds
      final roundsSnapshot = await _firestore
          .collection('rounds')
          .where('matchId', isEqualTo: _firestore.collection('matches').doc(match.id))
          .orderBy('timestamp', descending: false)
          .get();
      
      final rounds = roundsSnapshot.docs
          .map((doc) => RoundModel.fromFirestore(doc))
          .toList();
      
      // Calculer les scores actuels
      final Map<String, double> currentScores = {
        match.player1.id: 0.0,
        match.player2.id: 0.0,
      };
      
      for (final round in rounds) {
        final playerId = round.playerId.id;
        currentScores[playerId] = (currentScores[playerId] ?? 0.0) + round.totalScore;
      }
      
      // Déterminer le statut
      String status = 'En attente';
      if (match.status == MatchStatus.inProgress) {
        if (rounds.isNotEmpty) {
          final lastRound = rounds.last;
          final timeSinceLastRound = DateTime.now().difference(lastRound.timestamp);
          if (timeSinceLastRound.inSeconds < 30) {
            status = 'Action en cours !';
          } else {
            status = 'En cours';
          }
        } else {
          status = 'Démarré';
        }
      } else if (match.status == MatchStatus.finished) {
        status = 'Terminé';
      }
      
      return LiveMatchData(
        match: match,
        player1: player1,
        player2: player2,
        rounds: rounds,
        currentScores: currentScores,
        status: status,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      Logger.error(' Erreur construction live match data: $e');
      rethrow;
    }
  }

  /// Calculer les statistiques globales d'événement
  static Future<EventStats> _calculateEventStats() async {
    try {
      // Compter les matchs
      final allMatchesSnapshot = await _firestore.collection('matches').get();
      final totalMatches = allMatchesSnapshot.docs.length;
      
      int activeMatches = 0;
      int completedMatches = 0;
      
      for (final doc in allMatchesSnapshot.docs) {
        final match = MatchModel.fromFirestore(doc);
        if (match.status == MatchStatus.inProgress || match.status == MatchStatus.pending) {
          activeMatches++;
        } else if (match.status == MatchStatus.finished) {
          completedMatches++;
        }
      }
      
      // Compter les joueurs uniques
      final usersSnapshot = await _firestore.collection('users').get();
      final totalPlayers = usersSnapshot.docs.length;
      
      // Compter les sorts lancés
      final roundsSnapshot = await _firestore.collection('rounds').get();
      final totalSpellsCast = roundsSnapshot.docs.length;
      
      // Calculer la durée moyenne des matchs (estimation)
      double averageMatchDuration = 0.0;
      if (completedMatches > 0) {
        // Estimation basée sur 2 minutes par round en moyenne
        final avgRoundsPerMatch = totalSpellsCast / (totalMatches > 0 ? totalMatches : 1);
        averageMatchDuration = avgRoundsPerMatch * 2.0; // 2 min par round
      }
      
      // Sort le plus utilisé
      String mostUsedSpell = '';
      if (roundsSnapshot.docs.isNotEmpty) {
        final Map<String, int> spellCount = {};
        for (final doc in roundsSnapshot.docs) {
          final round = RoundModel.fromFirestore(doc);
          spellCount[round.spellCast] = (spellCount[round.spellCast] ?? 0) + 1;
        }
        
        if (spellCount.isNotEmpty) {
          mostUsedSpell = spellCount.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }
      
      return EventStats(
        totalMatches: totalMatches,
        activeMatches: activeMatches,
        completedMatches: completedMatches,
        totalPlayers: totalPlayers,
        totalSpellsCast: totalSpellsCast,
        averageMatchDuration: averageMatchDuration,
        mostUsedSpell: mostUsedSpell,
      );
    } catch (e) {
      Logger.error(' Erreur calcul event stats: $e');
      return EventStats();
    }
  }

  /// Obtenir le match le plus intéressant pour la projection
  static Future<LiveMatchData?> getFeaturedMatch() async {
    try {
      final liveMatches = await getLiveMatchesStream().first;
      
      if (liveMatches.isEmpty) return null;
      
      // Priorité : matchs en cours > matchs proches de la fin > matchs récents
      final sortedMatches = List<LiveMatchData>.from(liveMatches);
      
      sortedMatches.sort((a, b) {
        // Matchs en cours d'abord
        if (a.match.status != b.match.status) {
          return a.match.status == MatchStatus.inProgress ? -1 : 1;
        }
        
        // Puis matchs proches de la fin
        if (a.isNearEnd != b.isNearEnd) {
          return a.isNearEnd ? -1 : 1;
        }
        
        // Puis par activité récente
        return b.lastUpdate.compareTo(a.lastUpdate);
      });
      
      return sortedMatches.first;
    } catch (e) {
      Logger.error(' Erreur récupération featured match: $e');
      return null;
    }
  }

  /// Nettoyer les streams
  static void dispose() {
    _liveMatchesController?.close();
    _eventStatsController?.close();
    _liveMatchesController = null;
    _eventStatsController = null;
  }

  /// Forcer le refresh des données
  static Future<void> refreshData() async {
    // Les streams se mettent à jour automatiquement
    // Cette méthode peut être étendue pour d'autres actions
    Logger.debug('🔄 Refresh des données Game Master');
  }
} 