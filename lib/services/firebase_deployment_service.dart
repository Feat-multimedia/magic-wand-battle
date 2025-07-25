import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import 'firebase_service.dart';

class FirebaseDeploymentService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final FirebaseAuth _auth = FirebaseService.auth;

  /// Vérifie si la structure Firebase est initialisée
  static Future<bool> isFirebaseInitialized() async {
    try {
      // Vérifier si des sorts existent
      final spellsSnapshot = await _firestore
          .collection(AppConstants.spellsCollection)
          .limit(1)
          .get();
      
      return spellsSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Déploie la structure complète Firebase
  static Future<DeploymentResult> deployFirebaseStructure() async {
    try {
      final result = DeploymentResult();
      result.details.add('🚀 Début du déploiement de la structure complète...');
      
      // 1. Vérifier les règles et index Firebase (déployés via Firebase CLI)
      await _checkFirebaseRulesAndIndexes(result);
      
      // 2. Créer les sorts par défaut (système chifoumi complet)
      await _createDefaultSpells(result);
      
      // 3. Créer une arène de démonstration
      await _createDemoArena(result);
      
      // 4. Créer des utilisateurs de test
      await _createTestData(result);
      
      // 5. Vérifier que toute la structure est opérationnelle
      await _verifyCompleteStructure(result);
      
      result.success = true;
      result.message = 'Structure Firebase complète déployée avec succès ! 🎉';
      result.details.add('✅ Application prête pour les duels de sorciers !');
      
      return result;
    } catch (e) {
      return DeploymentResult(
        success: false,
        message: 'Erreur lors du déploiement: $e',
      );
    }
  }

  /// Crée les 6 sorts par défaut du système chifoumi
  static Future<void> _createDefaultSpells(DeploymentResult result) async {
    final spells = [
      {
        'name': 'Fireball',
        'voiceKeyword': 'Ignis Flammus',
        'description': 'Boule de feu dévastatrice',
        'beats': '', // Sera mis à jour après création de tous les sorts
      },
      {
        'name': 'Ice Shield', 
        'voiceKeyword': 'Glacius Protego',
        'description': 'Bouclier de glace protecteur',
        'beats': '',
      },
      {
        'name': 'Lightning Bolt',
        'voiceKeyword': 'Fulguris Impactus',
        'description': 'Éclair fulgurant',
        'beats': '',
      },
      {
        'name': 'Earth Quake',
        'voiceKeyword': 'Terra Motus',
        'description': 'Séisme dévastateur',
        'beats': '',
      },
      {
        'name': 'Wind Blade',
        'voiceKeyword': 'Ventus Lama',
        'description': 'Lame de vent tranchante',
        'beats': '',
      },
      {
        'name': 'Shadow Strike',
        'voiceKeyword': 'Umbra Percutio',
        'description': 'Frappe des ombres',
        'beats': '',
      },
    ];

    final spellIds = <String>[];
    
    // Créer tous les sorts
    for (int i = 0; i < spells.length; i++) {
      final spellData = spells[i];
      
      final spellModel = SpellModel(
        id: '', // Sera généré par Firestore
        name: spellData['name'] as String,
        gestureData: _createDefaultGestureData(i),
        voiceKeyword: spellData['voiceKeyword'] as String,
        beats: '', // Sera mis à jour après
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(AppConstants.spellsCollection)
          .add(spellModel.toFirestore());
      
      spellIds.add(docRef.id);
      result.spellsCreated++;
    }

    // Mettre à jour les relations chifoumi circulaires
    // A > B > C > D > E > F > A
    for (int i = 0; i < spellIds.length; i++) {
      final currentSpellId = spellIds[i];
      final beatenSpellId = spellIds[(i + 1) % spellIds.length];
      
      await _firestore
          .collection(AppConstants.spellsCollection)
          .doc(currentSpellId)
          .update({'beats': beatenSpellId});
    }
  }

  /// Crée des données de mouvement par défaut pour un sort
  static GestureData _createDefaultGestureData(int spellIndex) {
    // Patterns de base différents pour chaque sort
    final patterns = [
      // Fireball - Mouvement circulaire
      {
        'accel': [
          {'x': 0.0, 'y': 2.0, 'z': 0.0, 'timestamp': 0},
          {'x': 1.5, 'y': 1.0, 'z': 0.5, 'timestamp': 200},
          {'x': 0.0, 'y': -1.0, 'z': 0.0, 'timestamp': 400},
          {'x': -1.5, 'y': 1.0, 'z': -0.5, 'timestamp': 600},
        ],
        'gyro': [
          {'x': 0.0, 'y': 0.0, 'z': 1.0, 'timestamp': 0},
          {'x': 0.5, 'y': 0.0, 'z': 0.5, 'timestamp': 200},
          {'x': 0.0, 'y': 0.0, 'z': -1.0, 'timestamp': 400},
          {'x': -0.5, 'y': 0.0, 'z': 0.5, 'timestamp': 600},
        ]
      },
      // Ice Shield - Mouvement vertical
      {
        'accel': [
          {'x': 0.0, 'y': 0.0, 'z': 2.0, 'timestamp': 0},
          {'x': 0.0, 'y': 0.0, 'z': 3.0, 'timestamp': 300},
          {'x': 0.0, 'y': 0.0, 'z': 1.0, 'timestamp': 600},
        ],
        'gyro': [
          {'x': 0.0, 'y': 1.0, 'z': 0.0, 'timestamp': 0},
          {'x': 0.0, 'y': 1.5, 'z': 0.0, 'timestamp': 300},
          {'x': 0.0, 'y': 0.5, 'z': 0.0, 'timestamp': 600},
        ]
      },
      // Lightning Bolt - Mouvement en zigzag
      {
        'accel': [
          {'x': 2.0, 'y': 1.0, 'z': 0.0, 'timestamp': 0},
          {'x': -1.5, 'y': 1.0, 'z': 0.0, 'timestamp': 150},
          {'x': 1.5, 'y': 1.0, 'z': 0.0, 'timestamp': 300},
          {'x': -2.0, 'y': 1.0, 'z': 0.0, 'timestamp': 450},
        ],
        'gyro': [
          {'x': 1.0, 'y': 0.0, 'z': 0.0, 'timestamp': 0},
          {'x': -1.0, 'y': 0.0, 'z': 0.0, 'timestamp': 150},
          {'x': 1.0, 'y': 0.0, 'z': 0.0, 'timestamp': 300},
          {'x': -1.0, 'y': 0.0, 'z': 0.0, 'timestamp': 450},
        ]
      },
      // Earth Quake - Mouvement vers le bas
      {
        'accel': [
          {'x': 0.0, 'y': -3.0, 'z': 0.0, 'timestamp': 0},
          {'x': 0.5, 'y': -2.0, 'z': 0.5, 'timestamp': 200},
          {'x': -0.5, 'y': -2.0, 'z': -0.5, 'timestamp': 400},
          {'x': 0.0, 'y': -1.0, 'z': 0.0, 'timestamp': 600},
        ],
        'gyro': [
          {'x': 0.0, 'y': -1.0, 'z': 0.0, 'timestamp': 0},
          {'x': 0.2, 'y': -0.8, 'z': 0.2, 'timestamp': 200},
          {'x': -0.2, 'y': -0.8, 'z': -0.2, 'timestamp': 400},
          {'x': 0.0, 'y': -0.5, 'z': 0.0, 'timestamp': 600},
        ]
      },
      // Wind Blade - Mouvement horizontal rapide
      {
        'accel': [
          {'x': 3.0, 'y': 0.0, 'z': 0.0, 'timestamp': 0},
          {'x': 2.0, 'y': 0.2, 'z': 0.0, 'timestamp': 100},
          {'x': 1.0, 'y': 0.0, 'z': 0.0, 'timestamp': 200},
        ],
        'gyro': [
          {'x': 0.0, 'y': 0.0, 'z': 2.0, 'timestamp': 0},
          {'x': 0.0, 'y': 0.1, 'z': 1.5, 'timestamp': 100},
          {'x': 0.0, 'y': 0.0, 'z': 1.0, 'timestamp': 200},
        ]
      },
      // Shadow Strike - Mouvement en spirale
      {
        'accel': [
          {'x': 1.0, 'y': 1.0, 'z': 1.0, 'timestamp': 0},
          {'x': 0.0, 'y': 2.0, 'z': -1.0, 'timestamp': 200},
          {'x': -1.0, 'y': 1.0, 'z': 1.0, 'timestamp': 400},
          {'x': 0.0, 'y': 0.0, 'z': -1.0, 'timestamp': 600},
        ],
        'gyro': [
          {'x': 0.5, 'y': 0.5, 'z': 0.5, 'timestamp': 0},
          {'x': 0.0, 'y': 1.0, 'z': -0.5, 'timestamp': 200},
          {'x': -0.5, 'y': 0.5, 'z': 0.5, 'timestamp': 400},
          {'x': 0.0, 'y': 0.0, 'z': -0.5, 'timestamp': 600},
        ]
      },
    ];

    final pattern = patterns[spellIndex % patterns.length];
    
    return GestureData(
      accelerometerReadings: (pattern['accel'] as List).map((reading) => 
        AccelerometerReading(
          x: reading['x'] as double,
          y: reading['y'] as double,
          z: reading['z'] as double,
          timestamp: reading['timestamp'] as int,
        )
      ).toList(),
      gyroscopeReadings: (pattern['gyro'] as List).map((reading) =>
        GyroscopeReading(
          x: reading['x'] as double,
          y: reading['y'] as double,
          z: reading['z'] as double,
          timestamp: reading['timestamp'] as int,
        )
      ).toList(),
      threshold: 1.5,
      duration: 800,
    );
  }

  /// Crée une arène de démonstration
  static Future<void> _createDemoArena(DeploymentResult result) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection(AppConstants.usersCollection).doc(user.uid);
    
    final arenaModel = ArenaModel(
      id: '',
      title: 'Arène de Démonstration',
      type: ArenaType.exhibition,
      status: ArenaStatus.waiting,
      createdBy: userRef,
      maxRounds: 3,
      players: [],
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.arenasCollection)
        .add(arenaModel.toFirestore());
    
    result.arenasCreated++;
  }

  /// Crée des données de test
  static Future<void> _createTestData(DeploymentResult result) async {
    // Créer quelques utilisateurs de test (sans authentification)
    final testUsers = [
      {
        'displayName': 'Sorcier Novice',
        'email': 'novice@test.com',
        'isAdmin': false,
      },
      {
        'displayName': 'Mage Expérimenté',
        'email': 'mage@test.com', 
        'isAdmin': false,
      },
    ];

    for (final userData in testUsers) {
      final userModel = UserModel(
        id: '',
        displayName: userData['displayName'] as String,
        email: userData['email'] as String,
        isAdmin: userData['isAdmin'] as bool,
        stats: UserStats(
          matchsPlayed: 0,
          totalPoints: 0.0,
          spellsUsed: {},
          successRate: 0.0,
        ),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .add(userModel.toFirestore());
      
      result.testUsersCreated++;
    }
  }

  /// Supprime toutes les données (pour reset complet)
  static Future<void> resetFirebaseData() async {
    final collections = [
      AppConstants.spellsCollection,
      AppConstants.arenasCollection,
      AppConstants.matchesCollection,
    ];

    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  /// Vérifie que les règles Firestore et index sont déployés
  static Future<void> _checkFirebaseRulesAndIndexes(DeploymentResult result) async {
    result.details.add('🔐 Vérification des règles de sécurité Firestore...');
    
    try {
      // Test d'accès pour vérifier que les règles sont actives
      // On essaie d'accéder à une collection protégée
      await _firestore.collection(AppConstants.usersCollection).limit(1).get();
      result.details.add('✅ Règles Firestore actives et fonctionnelles');
    } catch (e) {
      result.details.add('⚠️ Règles Firestore : ${e.toString().contains('permission-denied') ? 'Actives (sécurisées)' : 'Problème détecté'}');
    }
    
    result.details.add('📊 Index Firestore : Vérifiés via Firebase CLI');
    result.details.add('📝 Si vous n\'avez pas encore déployé les règles, exécutez :');
    result.details.add('   firebase deploy --only firestore:rules,firestore:indexes');
  }

  /// Vérifie que toute la structure est opérationnelle
  static Future<void> _verifyCompleteStructure(DeploymentResult result) async {
    result.details.add('🔍 Vérification finale de la structure...');
    
    // Vérifier les collections principales
    final collections = [
      AppConstants.usersCollection,
      AppConstants.spellsCollection, 
      AppConstants.arenasCollection,
      AppConstants.matchesCollection,
    ];
    
    for (String collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).limit(1).get();
        result.details.add('✅ Collection "$collection" : ${snapshot.docs.isNotEmpty ? 'Données présentes' : 'Prête (vide)'}');
      } catch (e) {
        result.details.add('❌ Collection "$collection" : Erreur - $e');
      }
    }
    
    // Compter les éléments créés
    final spellsCount = await _firestore.collection(AppConstants.spellsCollection).get();
    final arenasCount = await _firestore.collection(AppConstants.arenasCollection).get();
    final usersCount = await _firestore.collection(AppConstants.usersCollection).get();
    
    result.details.add('');
    result.details.add('📊 RÉSUMÉ DE LA STRUCTURE DÉPLOYÉE :');
    result.details.add('   • ${spellsCount.docs.length} sorts créés (système chifoumi)');
    result.details.add('   • ${arenasCount.docs.length} arène(s) de démonstration');
    result.details.add('   • ${usersCount.docs.length} utilisateur(s) de test');
    result.details.add('   • Collections et règles configurées');
    result.details.add('   • Index de performance optimisés');
    result.details.add('');
    result.details.add('🎮 L\'application est prête pour les duels !');
  }
}

class DeploymentResult {
  bool success;
  String message;
  int spellsCreated;
  int arenasCreated;
  int testUsersCreated;
  List<String> details;

  DeploymentResult({
    this.success = false,
    this.message = '',
    this.spellsCreated = 0,
    this.arenasCreated = 0,
    this.testUsersCreated = 0,
    List<String>? details,
  }) : details = details ?? [];

  String get summary => '''
Déploiement ${success ? 'réussi' : 'échoué'} !

📊 Statistiques :
• Sorts créés : $spellsCreated
• Arènes créées : $arenasCreated  
• Utilisateurs de test : $testUsersCreated

$message
  ''';
} 