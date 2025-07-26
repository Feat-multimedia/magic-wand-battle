import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

/// ⚔️ **MatchService** - Gestion des matchs de tournoi
/// 
/// **Fonctionnalités :**
/// - Démarrer et terminer des matchs
/// - Mettre à jour les scores
/// - Progresser dans les brackets
/// - Notifications des résultats
class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// 🎯 **GESTION DES MATCHS**

  /// ▶️ **Démarrer un match**
  Future<bool> startMatch(String matchId) async {
    try {
      final matchDoc = await _firestore
          .collection('tournament_matches')
          .doc(matchId)
          .get();

      if (!matchDoc.exists) {
        Logger.warning('Match non trouvé: $matchId');
        return false;
      }

      final match = BracketMatch.fromFirestore(matchDoc);
      
      if (!match.isReady) {
        Logger.warning('Match pas prêt: $matchId');
        return false;
      }

      // Mettre à jour le statut
      await _firestore
          .collection('tournament_matches')
          .doc(matchId)
          .update({
        'status': BracketMatchStatus.inProgress.toString().split('.').last,
        'startedAt': Timestamp.now(),
      });

      Logger.success('Match démarré: $matchId');
      return true;
    } catch (e) {
      Logger.error('Erreur démarrage match', error: e);
      return false;
    }
  }

  /// 🏆 **Terminer un match avec résultats**
  Future<bool> finishMatch({
    required String matchId,
    required String winnerId,
    required double winnerScore,
    required double loserScore,
  }) async {
    try {
      final matchDoc = await _firestore
          .collection('tournament_matches')
          .doc(matchId)
          .get();

      if (!matchDoc.exists) return false;

      final match = BracketMatch.fromFirestore(matchDoc);
      final loserId = match.player1Id == winnerId ? match.player2Id : match.player1Id;

      // Mettre à jour le match
      final updatedMatch = match.copyWith(
        status: BracketMatchStatus.completed,
        winnerId: winnerId,
        loserId: loserId,
        player1Score: match.player1Id == winnerId ? winnerScore : loserScore,
        player2Score: match.player2Id == winnerId ? winnerScore : loserScore,
        completedAt: DateTime.now(),
      );

      await _firestore
          .collection('tournament_matches')
          .doc(matchId)
          .update(updatedMatch.toFirestore());

      Logger.success('Match terminé: $matchId - Gagnant: $winnerId');

      // Progresser dans le bracket
      await _progressBracket(match.tournamentId, winnerId, loserId, match);

      // Notifier les joueurs
      await _notifyMatchResult(winnerId, loserId, winnerScore, loserScore);

      return true;
    } catch (e) {
      Logger.error('Erreur fin match', error: e);
      return false;
    }
  }

  /// 📊 **Récupérer les matchs d'un tournoi en temps réel**
  Stream<List<BracketMatch>> getMatchesStream(String tournamentId) {
    return _firestore
        .collection('tournament_matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BracketMatch.fromFirestore(doc))
            .toList());
  }

  /// 🎯 **Récupérer les matchs prêts à jouer**
  Future<List<BracketMatch>> getReadyMatches(String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection('tournament_matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('status', isEqualTo: BracketMatchStatus.ready.toString().split('.').last)
          .get();

      return snapshot.docs
          .map((doc) => BracketMatch.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Erreur récupération matchs prêts', error: e);
      return [];
    }
  }

  /// 📈 **Obtenir les statistiques d'un match**
  Future<Map<String, dynamic>> getMatchStats(String matchId) async {
    try {
      final doc = await _firestore
          .collection('tournament_matches')
          .doc(matchId)
          .get();

      if (!doc.exists) return {};

      final match = BracketMatch.fromFirestore(doc);
      
      return {
        'isCompleted': match.isCompleted,
        'hasWinner': match.hasWinner,
        'duration': match.startedAt != null && match.completedAt != null
            ? match.completedAt!.difference(match.startedAt!).inMinutes
            : null,
        'round': match.round,
        'type': match.type.toString().split('.').last,
      };
    } catch (e) {
      Logger.error('Erreur stats match', error: e);
      return {};
    }
  }

  /// 🏗️ **PROGRESSION DU BRACKET**

  /// ⬆️ **Faire progresser le gagnant dans le bracket**
  Future<void> _progressBracket(
    String tournamentId,
    String winnerId,
    String? loserId,
    BracketMatch completedMatch,
  ) async {
    try {
      // Si il y a un match suivant, y placer le gagnant
      if (completedMatch.nextMatchId != null) {
        await _setPlayerInMatch(
          completedMatch.nextMatchId!,
          winnerId,
          _getPlayerSlotInNextMatch(completedMatch),
        );
      }

      // Pour la double élimination, gérer le perdant
      if (completedMatch.loserNextMatchId != null && loserId != null) {
        await _setPlayerInMatch(
          completedMatch.loserNextMatchId!,
          loserId,
          _getLoserSlotInNextMatch(completedMatch),
        );
      }

      // Vérifier si le tournoi est terminé
      await _checkTournamentCompletion(tournamentId);
    } catch (e) {
      Logger.error('Erreur progression bracket', error: e);
    }
  }

  /// 👤 **Placer un joueur dans un match**
  Future<void> _setPlayerInMatch(
    String matchId,
    String playerId,
    int playerSlot, // 1 ou 2
  ) async {
    final updateData = <String, dynamic>{};
    
    if (playerSlot == 1) {
      updateData['player1Id'] = playerId;
    } else {
      updateData['player2Id'] = playerId;
    }

    // Vérifier si le match est maintenant prêt
    final matchDoc = await _firestore
        .collection('tournament_matches')
        .doc(matchId)
        .get();
    
    if (matchDoc.exists) {
      final match = BracketMatch.fromFirestore(matchDoc);
      final otherPlayerId = playerSlot == 1 ? match.player2Id : match.player1Id;
      
      if (otherPlayerId != null) {
        // Les deux joueurs sont présents, le match est prêt
        updateData['status'] = BracketMatchStatus.ready.toString().split('.').last;
      }
    }

    await _firestore
        .collection('tournament_matches')
        .doc(matchId)
        .update(updateData);
  }

  /// 🔢 **Déterminer le slot du gagnant dans le match suivant**
  int _getPlayerSlotInNextMatch(BracketMatch match) {
    // Pour l'instant, alternance simple
    return (match.position % 2) + 1;
  }

  /// 🔢 **Déterminer le slot du perdant dans le bracket perdant**
  int _getLoserSlotInNextMatch(BracketMatch match) {
    // Logique spécifique à la double élimination
    return 1; // Simplifiée pour l'instant
  }

  /// 🏁 **Vérifier si le tournoi est terminé**
  Future<void> _checkTournamentCompletion(String tournamentId) async {
    try {
      // Récupérer tous les matchs du tournoi
      final snapshot = await _firestore
          .collection('tournament_matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      final matches = snapshot.docs
          .map((doc) => BracketMatch.fromFirestore(doc))
          .toList();

      // Trouver le match final
      final finalMatch = matches
          .where((m) => m.type == BracketMatchType.final_)
          .isNotEmpty
          ? matches.firstWhere((m) => m.type == BracketMatchType.final_)
          : null;

      // Si la finale est terminée, terminer le tournoi
      if (finalMatch != null && finalMatch.isCompleted) {
        await _finishTournament(tournamentId, finalMatch.winnerId!);
      }
    } catch (e) {
      Logger.error('Erreur vérification fin tournoi', error: e);
    }
  }

  /// 🏆 **Terminer le tournoi**
  Future<void> _finishTournament(String tournamentId, String championId) async {
    try {
      await _firestore.collection('tournaments').doc(tournamentId).update({
        'status': TournamentStatus.finished.toString().split('.').last,
        'endDate': Timestamp.now(),
      });

      Logger.success('Tournoi terminé: $tournamentId - Champion: $championId');

      // TODO: Distribuer les récompenses
      // TODO: Notifier tous les participants
    } catch (e) {
      Logger.error('Erreur fin tournoi', error: e);
    }
  }

  /// 🔔 **NOTIFICATIONS**

  /// 📢 **Notifier le résultat d'un match**
  Future<void> _notifyMatchResult(
    String winnerId,
    String? loserId,
    double winnerScore,
    double loserScore,
  ) async {
    try {
      // Créer les notifications pour les joueurs
      final batch = FirebaseFirestore.instance.batch();
      
      // Notification pour le gagnant
      final winnerNotifRef = FirebaseFirestore.instance.collection('notifications').doc();
      final winnerNotification = {
        'id': winnerNotifRef.id,
        'userId': winnerId,
        'type': 'match_result',
        'title': '🎉 Victoire !',
        'message': 'Vous avez gagné votre match ! Score: ${winnerScore.toStringAsFixed(1)}',
        'data': {
          'result': 'win',
          'score': winnerScore,
          'opponentScore': loserScore,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(winnerNotifRef, winnerNotification);
      
      // Notification pour le perdant (si applicable)
      if (loserId != null) {
        final loserNotifRef = FirebaseFirestore.instance.collection('notifications').doc();
        final loserNotification = {
          'id': loserNotifRef.id,
          'userId': loserId,
          'type': 'match_result',
          'title': '⚔️ Match terminé',
          'message': 'Votre match s\'est terminé. Score: ${loserScore.toStringAsFixed(1)}',
          'data': {
            'result': 'loss',
            'score': loserScore,
            'opponentScore': winnerScore,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        };
        batch.set(loserNotifRef, loserNotification);
      }
      
      // Exécuter toutes les notifications
      await batch.commit();
      
      Logger.success('Notifications match envoyées - Gagnant: $winnerId, Perdant: $loserId');
    } catch (e) {
      Logger.error('Erreur envoi notifications match', error: e);
    }
  }

  /// 🎯 **UTILITAIRES**

  /// ⏱️ **Obtenir la durée d'un match**
  Duration? getMatchDuration(BracketMatch match) {
    if (match.startedAt != null && match.completedAt != null) {
      return match.completedAt!.difference(match.startedAt!);
    }
    return null;
  }

  /// 📊 **Calculer le pourcentage de completion d'un tournoi**
  double calculateTournamentProgress(List<BracketMatch> matches) {
    if (matches.isEmpty) return 0.0;
    
    final completedMatches = matches.where((m) => m.isCompleted).length;
    return completedMatches / matches.length;
  }

  /// 🏆 **Obtenir le classement actuel (Round Robin)**
  List<Map<String, dynamic>> getRoundRobinStandings(List<BracketMatch> matches) {
    final playerStats = <String, Map<String, dynamic>>{};
    
    // Initialiser les stats pour chaque joueur
    for (final match in matches) {
      if (match.player1Id != null) {
        playerStats.putIfAbsent(match.player1Id!, () => {
          'playerId': match.player1Id!,
          'wins': 0,
          'losses': 0,
          'totalScore': 0.0,
          'matchesPlayed': 0,
        });
      }
      if (match.player2Id != null) {
        playerStats.putIfAbsent(match.player2Id!, () => {
          'playerId': match.player2Id!,
          'wins': 0,
          'losses': 0,
          'totalScore': 0.0,
          'matchesPlayed': 0,
        });
      }
    }

    // Calculer les stats pour chaque match terminé
    for (final match in matches.where((m) => m.isCompleted)) {
      if (match.player1Id != null && match.player2Id != null) {
        final player1Stats = playerStats[match.player1Id!]!;
        final player2Stats = playerStats[match.player2Id!]!;

        player1Stats['matchesPlayed']++;
        player2Stats['matchesPlayed']++;

        if (match.player1Score != null) {
          player1Stats['totalScore'] += match.player1Score!;
        }
        if (match.player2Score != null) {
          player2Stats['totalScore'] += match.player2Score!;
        }

        if (match.winnerId == match.player1Id) {
          player1Stats['wins']++;
          player2Stats['losses']++;
        } else if (match.winnerId == match.player2Id) {
          player2Stats['wins']++;
          player1Stats['losses']++;
        }
      }
    }

    // Trier par victoires puis par score total
    final standings = playerStats.values.toList();
    standings.sort((a, b) {
      final winsComparison = b['wins'].compareTo(a['wins']);
      if (winsComparison != 0) return winsComparison;
      return b['totalScore'].compareTo(a['totalScore']);
    });

    return standings;
  }

  /// 🏅 **Distribuer les récompenses du tournoi**
  Future<void> _distributeRewards(TournamentModel tournament, TournamentBracket bracket) async {
    try {
      if (tournament.rewards.isEmpty) {
        Logger.info('Aucune récompense à distribuer pour ${tournament.name}');
        return;
      }
      
      // Trouver le champion (vainqueur du dernier match)
      final finalMatches = bracket.matches
          .where((m) => m.type == BracketMatchType.final_ && m.status == BracketMatchStatus.completed)
          .toList();
      
      if (finalMatches.isEmpty) {
        Logger.warning('Aucun match final trouvé pour distribuer les récompenses');
        return;
      }
      
      final finalMatch = finalMatches.first;
      final champion = finalMatch.winnerId;
      final runnerUp = finalMatch.loserId;
      
      if (champion == null) {
        Logger.warning('Aucun champion identifié');
        return;
      }
      
      // Créer les récompenses dans Firestore
      final batch = FirebaseFirestore.instance.batch();
      
      // Champion (1ère place)
      final championRewards = tournament.rewards.where((r) => r.position == 1);
      for (final reward in championRewards) {
        final rewardRef = FirebaseFirestore.instance.collection('user_rewards').doc();
        batch.set(rewardRef, {
          'id': rewardRef.id,
          'userId': champion,
          'tournamentId': tournament.id,
          'tournamentName': tournament.name,
          'reward': reward.toMap(),
          'position': 1,
          'achievedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Runner-up (2ème place)
      if (runnerUp != null) {
        final runnerUpRewards = tournament.rewards.where((r) => r.position == 2);
        for (final reward in runnerUpRewards) {
          final rewardRef = FirebaseFirestore.instance.collection('user_rewards').doc();
          batch.set(rewardRef, {
            'id': rewardRef.id,
            'userId': runnerUp,
            'tournamentId': tournament.id,
            'tournamentName': tournament.name,
            'reward': reward.toMap(),
            'position': 2,
            'achievedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
      Logger.success('Récompenses distribuées pour ${tournament.name}');
    } catch (e) {
      Logger.error('Erreur distribution récompenses', error: e);
    }
  }

  /// 📢 **Notifier la fin du tournoi à tous les participants**
  Future<void> _notifyTournamentCompletion(TournamentModel tournament, TournamentBracket bracket) async {
    try {
      // Trouver le champion
      final finalMatches = bracket.matches
          .where((m) => m.type == BracketMatchType.final_ && m.status == BracketMatchStatus.completed)
          .toList();
          
      String championName = 'Inconnu';
      if (finalMatches.isNotEmpty && finalMatches.first.winnerId != null) {
        championName = finalMatches.first.winnerId!.substring(0, 8); // ID tronqué
      }
      
      // Créer les notifications pour tous les participants
      final batch = FirebaseFirestore.instance.batch();
      
      for (final playerId in tournament.registeredPlayerIds) {
        final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
        
        final isChampion = finalMatches.isNotEmpty && finalMatches.first.winnerId == playerId;
        
        final notification = {
          'id': notificationRef.id,
          'userId': playerId,
          'type': 'tournament_completed',
          'title': isChampion ? '🏆 Félicitations Champion !' : '🏁 Tournoi terminé',
          'message': isChampion 
              ? 'Vous avez remporté ${tournament.name} ! Bravo !'
              : '${tournament.name} est terminé. Champion: $championName',
          'data': {
            'tournamentId': tournament.id,
            'tournamentName': tournament.name,
            'champion': championName,
            'isChampion': isChampion,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        batch.set(notificationRef, notification);
      }
      
      await batch.commit();
      Logger.success('Notifications fin de tournoi envoyées à ${tournament.registeredPlayerIds.length} participants');
    } catch (e) {
      Logger.error('Erreur notifications fin tournoi', error: e);
    }
  }
} 