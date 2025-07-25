import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import 'firebase_service.dart';

class StatsService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Obtenir le nombre total d'utilisateurs
  static Future<int> getUsersCount() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.usersCollection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir le nombre total de sorts
  static Future<int> getSpellsCount() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.spellsCollection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir le nombre total d'arènes
  static Future<int> getArenasCount() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.arenasCollection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir le nombre total de matchs
  static Future<int> getMatchesCount() async {
    try {
      final snapshot = await _firestore.collection(AppConstants.matchesCollection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir toutes les statistiques d'un coup
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

  /// Stream pour les statistiques en temps réel
  static Stream<Map<String, int>> getStatsStream() async* {
    while (true) {
      yield await getAllStats();
      await Future.delayed(const Duration(seconds: 5)); // Mise à jour toutes les 5 secondes
    }
  }
} 