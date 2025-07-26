import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';

/// Service de reconnaissance vocale pour les incantations magiques
class VoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;
  static StreamController<String>? _recognitionController;

  /// Initialiser le service vocal
  static Future<bool> initialize() async {
    try {
      // Demander la permission microphone
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        Logger.error(' Permission microphone refusée');
        return false;
      }

      // Initialiser speech_to_text
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          Logger.error(' Erreur speech_to_text: ${error.errorMsg}');
        },
        onStatus: (status) {
          Logger.debug('🎤 Statut vocal: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        Logger.success(' Service vocal initialisé', tag: LogTags.firebase);
      } else {
        Logger.error(' Échec initialisation service vocal');
      }

      return _isInitialized;
    } catch (e) {
      Logger.error(' Erreur initialisation vocal: $e');
      return false;
    }
  }

  /// Démarrer l'écoute pour une ou plusieurs incantations
  static Future<bool> startListening({
    String expectedKeyword = '', // Peut être vide pour écoute libre
    List<String> expectedKeywords = const [], // Pour écouter plusieurs mots-clés
    required Function(bool isMatch, String recognizedText, String? matchedKeyword) onResult,
    int timeoutSeconds = 5,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      print('⚠️ Déjà en cours d\'écoute');
      return false;
    }

    try {
      _isListening = true;
      String recognizedText = '';

      await _speechToText.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords.toLowerCase().trim();
          Logger.debug('🎤 Texte reconnu: "$recognizedText"');
          
          if (result.finalResult) {
            _isListening = false;
            final matchResult = _compareIncantations(expectedKeyword, expectedKeywords, recognizedText);
            onResult(matchResult.isMatch, recognizedText, matchResult.matchedKeyword);
          }
        },
        listenFor: Duration(seconds: timeoutSeconds),
        pauseFor: Duration(seconds: 1),
        partialResults: true,
        localeId: 'fr_FR', // Français par défaut
        cancelOnError: true,
      );

      // Timeout automatique
      Timer(Duration(seconds: timeoutSeconds + 1), () {
        if (_isListening) {
          stopListening();
          onResult(false, recognizedText.isEmpty ? 'Aucun son détecté' : recognizedText, null);
        }
      });

      return true;
    } catch (e) {
      Logger.error(' Erreur démarrage écoute: $e');
      _isListening = false;
      return false;
    }
  }

  /// Arrêter l'écoute
  static Future<void> stopListening() async {
    if (_isListening && _speechToText.isListening) {
      await _speechToText.stop();
      _isListening = false;
      Logger.debug('🛑 Écoute vocale arrêtée');
    }
  }

  /// Comparer l'incantation avec un ou plusieurs mots-clés
  static IncantationMatch _compareIncantations(String singleKeyword, List<String> multipleKeywords, String recognized) {
    if (recognized.isEmpty) return IncantationMatch(false, null);

    final recognizedClean = recognized.toLowerCase().trim();
    Logger.debug('🔍 Analyse vocale: "$recognizedClean"');

    // Construire la liste complète des mots-clés à tester
    final allKeywords = <String>[];
    if (singleKeyword.isNotEmpty) allKeywords.add(singleKeyword);
    allKeywords.addAll(multipleKeywords);

    // Si aucun mot-clé spécifié, accepter tout
    if (allKeywords.isEmpty) return IncantationMatch(true, null);

    // Tester chaque mot-clé
    String? bestMatch;
    double bestScore = 0.0;

    for (String keyword in allKeywords) {
      if (keyword.isEmpty) continue;
      
      final keywordClean = keyword.toLowerCase().trim();
      
      // 1. Match exact
      if (recognizedClean == keywordClean) {
        Logger.success(' Match exact: "$keyword"', tag: LogTags.firebase);
        return IncantationMatch(true, keyword);
      }

      // 2. Match avec contenu
      if (recognizedClean.contains(keywordClean)) {
        Logger.success(' Match contenu: "$keyword"', tag: LogTags.firebase);
        return IncantationMatch(true, keyword);
      }

      // 3. Match phonétique approximatif
      final similarity = _calculateStringSimilarity(keywordClean, recognizedClean);
      if (similarity > bestScore) {
        bestScore = similarity;
        bestMatch = keyword;
      }
    }

    // Seuil de similarité phonétique
    if (bestScore >= 0.7) {
      Logger.success(' Match phonétique: "$bestMatch" (${(bestScore * 100).toStringAsFixed(1)}%)', tag: LogTags.firebase);
      return IncantationMatch(true, bestMatch);
    }

    Logger.error(' Aucun match trouvé (meilleur: ${(bestScore * 100).toStringAsFixed(1)}%)');
    return IncantationMatch(false, null);
  }

  /// Calculer la similarité entre deux chaînes (Levenshtein normalisé)
  static double _calculateStringSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    
    return 1.0 - (distance / maxLength);
  }

  /// Distance de Levenshtein (nombre de modifications nécessaires)
  static int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    // Créer une matrice de distance
    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    // Initialiser la première ligne et colonne
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Calculer la distance
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     // suppression
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Vérifier si le service est disponible
  static bool get isAvailable => _isInitialized;
  
  /// Vérifier si on est en train d'écouter
  static bool get isListening => _isListening;

  /// Nettoyer les ressources
  static Future<void> dispose() async {
    await stopListening();
    _recognitionController?.close();
    _recognitionController = null;
    _isInitialized = false;
  }
}

/// Résultat d'une comparaison d'incantation
class IncantationMatch {
  final bool isMatch;
  final String? matchedKeyword;

  IncantationMatch(this.isMatch, this.matchedKeyword);
} 