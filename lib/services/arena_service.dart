import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/arena_model.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

import '../utils/logger.dart';

/// Service pour gérer les arènes et les matchs
class ArenaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // GESTION DES ARÈNES
  // ========================================

  /// Créer une nouvelle arène
  static Future<String> createArena(ArenaModel arena) async {
    try {
      final docRef = await _firestore.collection('arenas').add(arena.toFirestore());
      Logger.success(' Arène créée avec ID: ${docRef.id}', tag: LogTags.firebase);
      return docRef.id;
    } catch (e) {
      Logger.error(' Erreur création arène: $e');
      rethrow;
    }
  }

  /// Récupérer toutes les arènes
  static Future<List<ArenaModel>> getAllArenas() async {
    try {
      final snapshot = await _firestore
          .collection('arenas')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ArenaModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error(' Erreur récupération arènes: $e');
      return [];
    }
  }

  /// Récupérer une arène par ID
  static Future<ArenaModel?> getArenaById(String arenaId) async {
    try {
      final doc = await _firestore.collection('arenas').doc(arenaId).get();
      if (doc.exists) {
        return ArenaModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error(' Erreur récupération arène: $e');
      return null;
    }
  }

  /// Mettre à jour le statut d'une arène
  static Future<void> updateArenaStatus(String arenaId, ArenaStatus status) async {
    try {
      await _firestore.collection('arenas').doc(arenaId).update({
        'status': status.toString().split('.').last,
      });
      Logger.success(' Statut arène mis à jour: $status', tag: LogTags.firebase);
    } catch (e) {
      Logger.error(' Erreur mise à jour statut arène: $e');
      rethrow;
    }
  }

  /// Supprimer une arène
  static Future<void> deleteArena(String arenaId) async {
    try {
      await _firestore.collection('arenas').doc(arenaId).delete();
      Logger.success(' Arène supprimée: $arenaId', tag: LogTags.firebase);
    } catch (e) {
      Logger.error(' Erreur suppression arène: $e');
      rethrow;
    }
  }

  // ========================================
  // GESTION DES MATCHS
  // ========================================

  /// Créer un nouveau match
  static Future<String> createMatch(MatchModel match) async {
    try {
      final docRef = await _firestore.collection('matches').add(match.toFirestore());
      Logger.success(' Match créé avec ID: ${docRef.id}', tag: LogTags.firebase);
      return docRef.id;
    } catch (e) {
      Logger.error(' Erreur création match: $e');
      rethrow;
    }
  }

  /// Récupérer tous les matchs d'une arène
  static Future<List<MatchModel>> getMatchesByArena(String arenaId) async {
    try {
      final arenaRef = _firestore.collection('arenas').doc(arenaId);
      final snapshot = await _firestore
          .collection('matches')
          .where('arenaId', isEqualTo: arenaRef)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error(' Erreur récupération matchs: $e');
      return [];
    }
  }

  /// Récupérer un match par ID
  static Future<MatchModel?> getMatchById(String matchId) async {
    try {
      final doc = await _firestore.collection('matches').doc(matchId).get();
      if (doc.exists) {
        return MatchModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error(' Erreur récupération match: $e');
      return null;
    }
  }

  /// Mettre à jour le statut d'un match
  static Future<void> updateMatchStatus(String matchId, MatchStatus status) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'status': status.toString().split('.').last,
      });
      Logger.success(' Statut match mis à jour: $status', tag: LogTags.firebase);
    } catch (e) {
      Logger.error(' Erreur mise à jour statut match: $e');
      rethrow;
    }
  }

  /// Définir le gagnant d'un match
  static Future<void> setMatchWinner(String matchId, String winnerId, {bool finishMatch = true}) async {
    try {
      final updates = <String, dynamic>{
        'winner': _firestore.collection('users').doc(winnerId),
      };

      if (finishMatch) {
        updates['status'] = MatchStatus.finished.toString().split('.').last;
      }

      await _firestore.collection('matches').doc(matchId).update(updates);
      Logger.success(' Gagnant défini pour le match: $winnerId', tag: LogTags.firebase);
    } catch (e) {
      Logger.error(' Erreur définition gagnant: $e');
      rethrow;
    }
  }

  // ========================================
  // UTILITAIRES
  // ========================================

  /// Récupérer les arènes où un joueur peut participer
  static Future<List<ArenaModel>> getAvailableArenasForPlayer(String playerId) async {
    try {
      final playerRef = _firestore.collection('users').doc(playerId);
      final snapshot = await _firestore
          .collection('arenas')
          .where('players', arrayContains: playerRef)
          .where('status', whereIn: ['waiting', 'inProgress'])
          .get();

      return snapshot.docs
          .map((doc) => ArenaModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error(' Erreur récupération arènes disponibles: $e');
      return [];
    }
  }

  /// Récupérer les matchs en cours pour un joueur
  static Future<List<MatchModel>> getActiveMatchesForPlayer(String playerId) async {
    try {
      final playerRef = _firestore.collection('users').doc(playerId);
      final snapshot = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'inProgress')
          .get();

      final matches = <MatchModel>[];
      for (final doc in snapshot.docs) {
        final match = MatchModel.fromFirestore(doc);
        // Vérifier si le joueur participe à ce match
        if (match.player1.id == playerId || match.player2.id == playerId) {
          matches.add(match);
        }
      }

      return matches;
    } catch (e) {
      Logger.error(' Erreur récupération matchs actifs: $e');
      return [];
    }
  }

  /// Récupérer le nom d'un utilisateur par référence
  static Future<String> getUserNameFromRef(DocumentReference userRef) async {
    try {
      final doc = await userRef.get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        return user.displayName;
      }
      return 'Utilisateur inconnu';
    } catch (e) {
      Logger.error(' Erreur récupération nom utilisateur: $e');
      return 'Erreur';
    }
  }

  /// Vérifier si un joueur peut rejoindre une arène
  static Future<bool> canPlayerJoinArena(String arenaId, String playerId) async {
    try {
      final arena = await getArenaById(arenaId);
      if (arena == null) return false;

      // Vérifier que l'arène n'est pas pleine
      if (arena.isFull) return false;

      // Vérifier que le joueur n'est pas déjà dans l'arène
      final playerRef = _firestore.collection('users').doc(playerId);
      return !arena.players.any((ref) => ref.id == playerRef.id);
    } catch (e) {
      Logger.error(' Erreur vérification accès arène: $e');
      return false;
    }
  }

  /// Stream des arènes en temps réel
  static Stream<List<ArenaModel>> getArenasStream() {
    return _firestore
        .collection('arenas')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ArenaModel.fromFirestore(doc))
            .toList());
  }

  /// Stream des matchs d'une arène en temps réel
  static Stream<List<MatchModel>> getMatchesStreamByArena(String arenaId) {
    final arenaRef = _firestore.collection('arenas').doc(arenaId);
    return _firestore
        .collection('matches')
        .where('arenaId', isEqualTo: arenaRef)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc))
            .toList());
  }

  /// 🔔 **Notifier les joueurs d'un nouveau match**
  Future<void> _notifyPlayersNewMatch(MatchModel match, List<UserModel> players) async {
    try {
      final notificationService = NotificationService();
      
      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        final opponent = players[1 - i]; // L'autre joueur
        
                         await notificationService.notifyNewMatch(
          playerId: player.id,
          opponentName: opponent.displayName,
          arenaName: 'Arène ${match.arenaId}', // TODO: récupérer le vrai nom d'arène
        );
      }
      
      Logger.notification(' Notifications nouveau match envoyées', tag: LogTags.notification);
    } catch (e) {
      Logger.error(' Erreur notification nouveau match: $e');
    }
  }

  /// 🔔 **Notifier les joueurs du résultat du match**
  Future<void> _notifyPlayersMatchResult(MatchModel match) async {
    try {
      final notificationService = NotificationService();
      
             // Pour l'instant, simulation simple du résultat
       // TODO: Intégrer les vrais scores du match
       final hasWinner = match.winner != null;
       
       if (hasWinner) {
         final winnerId = match.winner!.id;
         final loserId = match.player1.id == winnerId ? match.player2.id : match.player1.id;
         
                 await notificationService.notifyVictory(
          playerId: winnerId,
          opponentName: 'Adversaire', // TODO: récupérer le vrai nom
          score: 10.0, // Score simulé
        );
        await notificationService.notifyDefeat(
          playerId: loserId,
          opponentName: 'Adversaire', // TODO: récupérer le vrai nom
          score: 5.0, // Score simulé
        );
       }
      // En cas d'égalité, pas de notification de victoire/défaite
      
      Logger.notification(' Notifications résultat match envoyées', tag: LogTags.notification);
    } catch (e) {
      Logger.error(' Erreur notification résultat: $e');
    }
  }
} 