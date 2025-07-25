import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spell_model.dart';
import '../constants/app_constants.dart';
import 'firebase_service.dart';

class SpellService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static final CollectionReference _spellsCollection = 
      _firestore.collection(AppConstants.spellsCollection);

  /// Récupérer tous les sorts
  static Future<List<SpellModel>> getAllSpells() async {
    try {
      final QuerySnapshot snapshot = await _spellsCollection
          .orderBy('createdAt', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        return SpellModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des sorts: $e');
    }
  }

  /// Stream pour écouter les changements des sorts
  static Stream<List<SpellModel>> getSpellsStream() {
    return _spellsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return SpellModel.fromFirestore(doc);
          }).toList();
        });
  }

  /// Récupérer un sort par ID
  static Future<SpellModel?> getSpellById(String spellId) async {
    try {
      final DocumentSnapshot doc = await _spellsCollection.doc(spellId).get();
      
      if (doc.exists) {
        return SpellModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du sort: $e');
    }
  }

  /// Supprimer un sort
  static Future<void> deleteSpell(String spellId) async {
    try {
      await _spellsCollection.doc(spellId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du sort: $e');
    }
  }

  /// Supprimer plusieurs sorts
  static Future<void> deleteMultipleSpells(List<String> spellIds) async {
    try {
      final WriteBatch batch = _firestore.batch();
      
      for (String spellId in spellIds) {
        batch.delete(_spellsCollection.doc(spellId));
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression des sorts: $e');
    }
  }

  /// Créer un nouveau sort
  static Future<String> createSpell(SpellModel spell) async {
    try {
      final DocumentReference docRef = await _spellsCollection.add(spell.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du sort: $e');
    }
  }

  /// Mettre à jour un sort
  static Future<void> updateSpell(String spellId, SpellModel spell) async {
    try {
      await _spellsCollection.doc(spellId).update(spell.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du sort: $e');
    }
  }

  /// Supprimer tous les sorts (pour reset)
  static Future<void> deleteAllSpells() async {
    try {
      final QuerySnapshot snapshot = await _spellsCollection.get();
      final WriteBatch batch = _firestore.batch();
      
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de tous les sorts: $e');
    }
  }

  /// Vérifier les relations chifoumi (chaque sort doit battre exactement un autre)
  static Future<Map<String, String?>> checkChifoumiRelations() async {
    try {
      final List<SpellModel> spells = await getAllSpells();
      final Map<String, String?> relations = {};
      
      for (SpellModel spell in spells) {
        relations[spell.id] = spell.beats;
      }
      
      return relations;
    } catch (e) {
      throw Exception('Erreur lors de la vérification des relations: $e');
    }
  }

  /// Réparer les relations chifoumi pour un système circulaire
  static Future<void> fixChifoumiRelations(List<String> spellIds) async {
    try {
      if (spellIds.length < 2) {
        throw Exception('Il faut au moins 2 sorts pour établir des relations');
      }

      final WriteBatch batch = _firestore.batch();
      
      // Créer un système circulaire : sort[i] bat sort[i+1], dernier bat premier
      for (int i = 0; i < spellIds.length; i++) {
        final currentSpellId = spellIds[i];
        final beatenSpellId = spellIds[(i + 1) % spellIds.length];
        
        batch.update(_spellsCollection.doc(currentSpellId), {
          'beats': beatenSpellId,
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la réparation des relations: $e');
    }
  }

  /// Obtenir les statistiques des sorts
  static Future<Map<String, dynamic>> getSpellStats() async {
    try {
      final List<SpellModel> spells = await getAllSpells();
      final Map<String, String?> relations = await checkChifoumiRelations();
      
      int validRelations = 0;
      int invalidRelations = 0;
      
      for (String spellId in relations.keys) {
        if (relations[spellId] != null && relations[spellId]!.isNotEmpty) {
          validRelations++;
        } else {
          invalidRelations++;
        }
      }
      
      return {
        'total': spells.length,
        'validRelations': validRelations,
        'invalidRelations': invalidRelations,
        'isSystemValid': spells.length >= 3 && invalidRelations == 0,
      };
    } catch (e) {
      return {
        'total': 0,
        'validRelations': 0,
        'invalidRelations': 0,
        'isSystemValid': false,
      };
    }
  }
} 