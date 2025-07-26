import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// 🏆 **TournamentService** - Gestion complète des tournois
/// 
/// **Fonctionnalités :**
/// - CRUD des tournois
/// - Génération automatique de brackets
/// - Gestion des inscriptions
/// - Logique de progression des matchs
/// - Attribution des récompenses
/// - Notifications tournois
class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// 📊 **CRUD TOURNOIS**

  /// 🆕 **Créer un nouveau tournoi**
  Future<TournamentModel> createTournament({
    required String name,
    required String description,
    required TournamentType type,
    required int maxParticipants,
    int minParticipants = 2,
    DateTime? startDate,
    DateTime? registrationDeadline,
    String? arenaId,
    List<String>? allowedSpellIds,
    List<TournamentReward> rewards = const [],
    Map<String, dynamic> rules = const {},
  }) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      Logger.operation('Création tournoi: $name', tag: LogTags.admin);

      final tournament = TournamentModel(
        id: '', // Sera défini par Firestore
        name: name,
        description: description,
        type: type,
        status: TournamentStatus.draft,
        createdAt: DateTime.now(),
        startDate: startDate,
        registrationDeadline: registrationDeadline,
        maxParticipants: maxParticipants,
        minParticipants: minParticipants,
        organizerId: currentUser.uid,
        arenaId: arenaId,
        allowedSpellIds: allowedSpellIds,
        rules: rules,
        rewards: rewards,
      );

      final docRef = await _firestore
          .collection('tournaments')
          .add(tournament.toFirestore());

      final createdTournament = tournament.copyWith();
      Logger.success('Tournoi créé: ${docRef.id}', tag: LogTags.admin);

      return createdTournament;
    } catch (e) {
      Logger.error('Erreur création tournoi', tag: LogTags.admin, error: e);
      rethrow;
    }
  }

  /// 📋 **Récupérer tous les tournois**
  Future<List<TournamentModel>> getAllTournaments() async {
    try {
      final snapshot = await _firestore
          .collection('tournaments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TournamentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Erreur récupération tournois', error: e);
      return [];
    }
  }

  /// 🔄 **Stream des tournois en temps réel**
  Stream<List<TournamentModel>> getTournamentsStream() {
    return _firestore
        .collection('tournaments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentModel.fromFirestore(doc))
            .toList());
  }

  /// 🎯 **Récupérer un tournoi par ID**
  Future<TournamentModel?> getTournamentById(String tournamentId) async {
    try {
      final doc = await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .get();

      if (!doc.exists) return null;
      return TournamentModel.fromFirestore(doc);
    } catch (e) {
      Logger.error('Erreur récupération tournoi $tournamentId', error: e);
      return null;
    }
  }

  /// ✏️ **Mettre à jour un tournoi**
  Future<TournamentModel?> updateTournament(
    String tournamentId, 
    TournamentModel updatedTournament
  ) async {
    try {
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .update(updatedTournament.toFirestore());

      Logger.success('Tournoi mis à jour: $tournamentId', tag: LogTags.admin);
      return await getTournamentById(tournamentId);
    } catch (e) {
      Logger.error('Erreur mise à jour tournoi', error: e);
      return null;
    }
  }

  /// 🗑️ **Supprimer un tournoi**
  Future<bool> deleteTournament(String tournamentId) async {
    try {
      // Supprimer tous les matches associés
      await _deleteTournamentMatches(tournamentId);
      
      // Supprimer le tournoi
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .delete();

      Logger.success('Tournoi supprimé: $tournamentId', tag: LogTags.admin);
      return true;
    } catch (e) {
      Logger.error('Erreur suppression tournoi', error: e);
      return false;
    }
  }

  /// 📊 **GESTION DES INSCRIPTIONS**

  /// ✅ **Inscrire un joueur au tournoi**
  Future<bool> registerPlayer(String tournamentId, String playerId) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        Logger.warning('Tournoi non trouvé: $tournamentId');
        return false;
      }

      if (!tournament.canRegister(playerId)) {
        Logger.warning('Inscription impossible pour $playerId au tournoi $tournamentId');
        return false;
      }

      final updatedPlayerIds = [...tournament.registeredPlayerIds, playerId];
      await _firestore.collection('tournaments').doc(tournamentId).update({
        'registeredPlayerIds': updatedPlayerIds,
      });

      // 🔔 Notification à l'organisateur
      await _notificationService.notifyAdminNewPlayer(
        playerName: 'Joueur', // Placeholder, actual name will be fetched
        playerEmail: '', // Placeholder, actual email will be fetched
      );

      Logger.success('Joueur $playerId inscrit au tournoi $tournamentId');
      return true;
    } catch (e) {
      Logger.error('Erreur inscription joueur', error: e);
      return false;
    }
  }

  /// ❌ **Désinscrire un joueur du tournoi**
  Future<bool> unregisterPlayer(String tournamentId, String playerId) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) return false;

      final updatedPlayerIds = tournament.registeredPlayerIds
          .where((id) => id != playerId)
          .toList();

      await _firestore.collection('tournaments').doc(tournamentId).update({
        'registeredPlayerIds': updatedPlayerIds,
      });

      Logger.success('Joueur $playerId désinscrit du tournoi $tournamentId');
      return true;
    } catch (e) {
      Logger.error('Erreur désinscription joueur', error: e);
      return false;
    }
  }

  /// 🎯 **GESTION DES BRACKETS**

  /// 🏗️ **Générer bracket basé sur le type de tournoi**
  Future<TournamentBracket> generateBracket(String tournamentId) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) {
        throw Exception('Tournoi non trouvé: $tournamentId');
      }

      Logger.operation('Génération bracket pour tournoi $tournamentId');

      final players = List<String>.from(tournament.registeredPlayerIds);
      List<BracketMatch> matches;

      switch (tournament.type) {
        case TournamentType.singleElimination:
          matches = _generateSingleEliminationBracket(tournamentId, players);
          break;
        case TournamentType.doubleElimination:
          // Pour l'instant, utiliser single elimination avec TODO
          matches = _generateSingleEliminationBracket(tournamentId, players);
          Logger.warning('Double élimination pas encore implémentée, utilisation single elimination');
          break;
        case TournamentType.roundRobin:
          matches = _generateRoundRobinBracket(tournamentId, players);
          break;
        case TournamentType.swiss:
          // Pour l'instant, utiliser round robin avec TODO
          matches = _generateSwissBracket(tournamentId, players);
          Logger.warning('Système suisse pas encore implémenté, utilisation round robin');
          break;
      }

      // Sauvegarder tous les matches
      for (final match in matches) {
        await _firestore
            .collection('tournament_matches')
            .doc(match.id)
            .set(match.toFirestore());
      }

      final bracket = TournamentBracket(
        id: '${tournamentId}_bracket',
        tournamentId: tournamentId,
        type: tournament.type,
        matches: matches,
        roundMatches: _organizeMatchesByRound(matches),
        createdAt: DateTime.now(),
      );

      Logger.success('Bracket généré: ${matches.length} matches créés');
      return bracket;
    } catch (e) {
      Logger.error('Erreur génération bracket', error: e);
      rethrow;
    }
  }

  /// 📊 **Récupérer le bracket d'un tournoi**
  Future<TournamentBracket?> getTournamentBracket(String tournamentId) async {
    try {
      final snapshot = await _firestore
          .collection('tournament_matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final matches = snapshot.docs
          .map((doc) => BracketMatch.fromFirestore(doc))
          .toList();

      final tournament = await getTournamentById(tournamentId);
      if (tournament == null) return null;

      return TournamentBracket.fromMatches(
        id: '${tournamentId}_bracket',
        tournamentId: tournamentId,
        type: tournament.type,
        matches: matches,
      );
    } catch (e) {
      Logger.error('Erreur récupération bracket', error: e);
      return null;
    }
  }

  /// 🏗️ **GÉNÉRATION DE BRACKETS SPÉCIALISÉS**

  /// ⚡ **Génération bracket élimination directe**
  List<BracketMatch> _generateSingleEliminationBracket(
    String tournamentId, 
    List<String> players
  ) {
    final matches = <BracketMatch>[];
    final shuffledPlayers = List.from(players)..shuffle();
    
    // Calculer le nombre de rounds nécessaires
    final totalRounds = (log(shuffledPlayers.length) / log(2)).ceil();
    var currentRound = 1;
    var matchPosition = 0;
    
    // Premier round : tous les joueurs
    for (int i = 0; i < shuffledPlayers.length; i += 2) {
      final match = BracketMatch(
        id: '${tournamentId}_r${currentRound}_m$matchPosition',
        tournamentId: tournamentId,
        round: currentRound,
        position: matchPosition,
        type: totalRounds == 1 ? BracketMatchType.final_ : BracketMatchType.elimination,
        status: BracketMatchStatus.ready,
        player1Id: shuffledPlayers[i],
        player2Id: i + 1 < shuffledPlayers.length ? shuffledPlayers[i + 1] : null,
      );
      matches.add(match);
      matchPosition++;
    }

    // Rounds suivants : matches vides qui seront remplis par les gagnants
    for (int round = 2; round <= totalRounds; round++) {
      final matchesInRound = pow(2, totalRounds - round).toInt();
      for (int pos = 0; pos < matchesInRound; pos++) {
        final isFinale = round == totalRounds;
        final match = BracketMatch(
          id: '${tournamentId}_r${round}_m$pos',
          tournamentId: tournamentId,
          round: round,
          position: pos,
          type: isFinale ? BracketMatchType.final_ : 
                (round == totalRounds - 1 ? BracketMatchType.semifinal : BracketMatchType.elimination),
          status: BracketMatchStatus.pending,
        );
        matches.add(match);
      }
    }

    return matches;
  }

  /// 🔄 **Génération bracket double élimination** (version simplifiée)
  List<BracketMatch> _generateDoubleEliminationBracket(
    String tournamentId, 
    List<String> players
  ) {
    // Pour l'instant, utiliser single elimination 
    // TODO: Implémenter la vraie double élimination
    Logger.warning('Double élimination pas encore implémentée, utilisation single elimination');
    return _generateSingleEliminationBracket(tournamentId, players);
  }

  /// 🔄 **Génération bracket round robin**
  List<BracketMatch> _generateRoundRobinBracket(
    String tournamentId, 
    List<String> players
  ) {
    final matches = <BracketMatch>[];
    var matchId = 0;

    // Tous contre tous
    for (int i = 0; i < players.length; i++) {
      for (int j = i + 1; j < players.length; j++) {
        final match = BracketMatch(
          id: '${tournamentId}_rr_$matchId',
          tournamentId: tournamentId,
          round: 1, // Tous les matches sont au round 1 en round robin
          position: matchId,
          type: BracketMatchType.qualification,
          status: BracketMatchStatus.ready,
          player1Id: players[i],
          player2Id: players[j],
        );
        matches.add(match);
        matchId++;
      }
    }

    return matches;
  }

  /// ♟️ **Génération bracket système suisse**
  List<BracketMatch> _generateSwissBracket(
    String tournamentId, 
    List<String> players
  ) {
    final matches = <BracketMatch>[];
    
    if (players.length < 2) return matches;
    
    // Le système suisse fonctionne en rounds où chaque joueur affronte
    // un adversaire avec un score similaire
    
    // Nombre de rounds = ceil(log2(nombre de joueurs))
    final roundCount = (log(players.length) / log(2)).ceil();
    Logger.info('Système suisse: ${players.length} joueurs, $roundCount rounds');
    
    // Round 1: Appariements aléatoires
    final shuffledPlayers = List<String>.from(players)..shuffle();
    var matchCounter = 1;
    
    // Créer les matches du premier round
    for (int i = 0; i < shuffledPlayers.length; i += 2) {
      if (i + 1 < shuffledPlayers.length) {
        final match = BracketMatch(
          id: 'swiss_r1_${matchCounter++}',
          tournamentId: tournamentId,
          round: 1,
          position: i ~/ 2,
          type: BracketMatchType.qualification,
          status: BracketMatchStatus.ready,
          player1Id: shuffledPlayers[i],
          player2Id: shuffledPlayers[i + 1],
        );
        matches.add(match);
      }
    }
    
    // Pour les rounds suivants, on créera les matches dynamiquement
    // basé sur les résultats précédents (système de "pairing based on score")
    
    // Rounds 2 à N: Matches seront créés dynamiquement par l'admin
    // basé sur les scores des joueurs après chaque round
    for (int round = 2; round <= roundCount; round++) {
      // Créer des matches "template" qui seront remplis plus tard
      final roundMatches = <BracketMatch>[];
      final expectedMatches = (players.length / 2).ceil();
      
      for (int i = 0; i < expectedMatches; i++) {
        final match = BracketMatch(
          id: 'swiss_r${round}_${i + 1}',
          tournamentId: tournamentId,
          round: round,
          position: i,
          type: round == roundCount ? BracketMatchType.final_ : BracketMatchType.qualification,
          status: BracketMatchStatus.pending,
          // Les joueurs seront assignés après les résultats du round précédent
        );
        roundMatches.add(match);
      }
      
      matches.addAll(roundMatches);
    }
    
    Logger.success('Système suisse généré: ${matches.length} matches sur $roundCount rounds');
    return matches;
  }

  /// 🎯 **GESTION DES MATCHS**

  /// ⚔️ **Démarrer un tournoi**
  Future<bool> startTournament(String tournamentId) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      if (tournament == null || tournament.status != TournamentStatus.ready) {
        return false;
      }

      final updatedTournament = tournament.copyWith(
        status: TournamentStatus.inProgress,
        startDate: DateTime.now(),
      );

      final docRef = _firestore.collection('tournaments').doc(tournamentId);
      await docRef.update(updatedTournament.toFirestore());

      // Générer le bracket
      await generateBracket(tournamentId);

      // 🔔 Notifier tous les participants du début du tournoi
      await _notifyTournamentStart(tournament);

      Logger.success('Tournoi $tournamentId démarré avec succès');
      return true;
    } catch (e) {
      Logger.error('Erreur démarrage tournoi $tournamentId', error: e);
      return false;
    }
  }

  /// 🏆 **Terminer un tournoi**
  Future<bool> finishTournament(String tournamentId) async {
    try {
      await _firestore.collection('tournaments').doc(tournamentId).update({
        'status': TournamentStatus.finished.toString().split('.').last,
        'endDate': Timestamp.now(),
      });

      Logger.success('Tournoi terminé: $tournamentId');
      return true;
    } catch (e) {
      Logger.error('Erreur fin tournoi', error: e);
      return false;
    }
  }

  /// 🧹 **UTILITAIRES PRIVÉS**

  /// 🗑️ **Supprimer tous les matches d'un tournoi**
  Future<void> _deleteTournamentMatches(String tournamentId) async {
    final snapshot = await _firestore
        .collection('tournament_matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// 📊 **Récupérer les statistiques d'un tournoi**
  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async {
    try {
      final tournament = await getTournamentById(tournamentId);
      final bracket = await getTournamentBracket(tournamentId);
      
      if (tournament == null) return {};

      return {
        'totalPlayers': tournament.registeredPlayerIds.length,
        'registrationProgress': tournament.registrationProgress,
        'totalMatches': bracket?.matches.length ?? 0,
        'completedMatches': bracket?.completedMatches.length ?? 0,
        'isComplete': bracket?.isComplete ?? false,
        'champion': bracket?.championId,
      };
    } catch (e) {
      Logger.error('Erreur stats tournoi', error: e);
      return {};
    }
  }

  /// 🗂️ **Organiser les matches par round**
  Map<int, List<BracketMatch>> _organizeMatchesByRound(List<BracketMatch> matches) {
    final roundMatches = <int, List<BracketMatch>>{};
    
    for (final match in matches) {
      roundMatches[match.round] ??= [];
      roundMatches[match.round]!.add(match);
    }
    
    return roundMatches;
  }

  /// 🔔 **Notifications**

  /// 📣 **Notifier tous les participants d'un tournoi**
  Future<void> _notifyTournamentStart(TournamentModel tournament) async {
    try {
      // Créer les notifications pour tous les participants
      final batch = _firestore.batch();
      
      for (final playerId in tournament.registeredPlayerIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        
        final notification = {
          'id': notificationRef.id,
          'userId': playerId,
          'type': 'tournament_started',
          'title': '🏆 Tournoi commencé !',
          'message': '${tournament.name} vient de commencer. Préparez vos baguettes !',
          'data': {
            'tournamentId': tournament.id,
            'tournamentName': tournament.name,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        batch.set(notificationRef, notification);
      }
      
      // Exécuter toutes les notifications en une fois
      await batch.commit();
      
      Logger.success('Notifications envoyées à ${tournament.registeredPlayerIds.length} participants');
    } catch (e) {
      Logger.error('Erreur envoi notifications début tournoi', error: e);
    }
  }
} 