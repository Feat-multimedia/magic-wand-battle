import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../models/spell_model.dart';
import '../../services/spell_service.dart';
import '../../services/gesture_service.dart';
import '../../services/advanced_gesture_service.dart';
import '../../services/gesture_pattern_service.dart';
import '../../services/voice_service.dart';
import '../../services/arena_service.dart';
import '../../services/audio_service.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../models/round_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/logger.dart';

enum DuelPhase {
  waiting,        // En attente
  gestureCapture, // Capture du geste
  processing,     // Traitement
  result,         // Résultat
}

class DuelScreen extends StatefulWidget {
  final String matchId;
  final String playerId;

  const DuelScreen({
    super.key,
    required this.matchId,
    required this.playerId,
  });

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> with TickerProviderStateMixin {
  DuelPhase _currentPhase = DuelPhase.waiting;
  List<SpellModel> _availableSpells = [];
  SpellModel? _selectedSpell;
  GestureData? _recordedGesture;
  
  // Données du match réel
  MatchModel? _currentMatch;
  UserModel? _currentUser;
  UserModel? _opponent;
  bool _isLoadingMatch = true;
  
  // Résultats
  double _gestureAccuracy = 0.0;
  String _detectedSpellName = '';
  bool _voiceBonus = false;
  String _voiceStatus = '';
  String _recognizedVoice = '';
  
  // État vocal pendant l'enregistrement
  bool _isVoiceListening = false;
  SpellModel? _detectedSpellFromVoice;
  
  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Timer pour capture automatique
  // Timer? _captureTimer; // Plus utilisé avec le contrôle manuel
  int _recordingProgress = 0;

  // 🎯 NOUVEAU: Mode entraînement simplifié
  bool get _isTrainingMode => widget.matchId == 'training';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSpells();
    if (!_isTrainingMode) {
      _loadMatchData();
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);
  }

  Future<void> _loadSpells() async {
    try {
      final spells = await SpellService.getAllSpells();
      setState(() {
        _availableSpells = spells;
      });
    } catch (e) {
      Logger.debug('Erreur lors du chargement des sorts: $e');
    }
  }

  /// 🆕 Charger les données du match réel depuis Firestore
  Future<void> _loadMatchData() async {
    if (_isTrainingMode) return;

    setState(() => _isLoadingMatch = true);
    
    try {
      // Charger le match
      final match = await ArenaService.getMatchById(widget.matchId);
      if (match == null) {
        throw Exception('Match introuvable');
      }

      // Charger les données utilisateur
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.playerId)
          .get();
      
      if (!currentUserDoc.exists) {
        throw Exception('Utilisateur introuvable');
      }

      final currentUser = UserModel.fromFirestore(currentUserDoc);

      // Déterminer l'adversaire
      final opponentRef = match.player1.id == widget.playerId 
          ? match.player2 
          : match.player1;
      
      final opponentDoc = await opponentRef.get();
      final opponent = UserModel.fromFirestore(opponentDoc);

      setState(() {
        _currentMatch = match;
        _currentUser = currentUser;
        _opponent = opponent;
        _isLoadingMatch = false;
      });

      Logger.success(' Match chargé: ${currentUser.displayName} vs ${opponent.displayName}', tag: LogTags.firebase);
    } catch (e) {
      Logger.error(' Erreur chargement match: $e');
      setState(() => _isLoadingMatch = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🆕 MÉTHODES UTILITAIRES POUR LE MATCH RÉEL

  /// Construire le titre du duel avec les noms des joueurs
  String _buildDuelTitle() {
    if (_currentUser == null || _opponent == null) {
      return 'Duel Magique';
    }
    return '⚔️ ${_currentUser!.displayName} vs ${_opponent!.displayName}';
  }

  /// Construire l'en-tête avec les informations des joueurs
  Widget _buildPlayersHeader() {
    if (_currentUser == null || _opponent == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Round 1 / ${_currentMatch?.roundsToWin ?? 3}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Joueur actuel
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        _currentUser!.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser!.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Vous',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // VS au centre
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              
              // Adversaire
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(
                        _opponent!.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _opponent!.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Adversaire',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
     }

  // 🔥 MÉTHODES DE RECONNAISSANCE GESTUELLE

  void _startGestureCapture() {
    setState(() {
      _currentPhase = DuelPhase.gestureCapture;
      _recordingProgress = 0;
    });
    
    // Pas de démarrage automatique - l'utilisateur contrôle maintenant
    Logger.game(' Mode capture prêt - Utilisateur doit appuyer et maintenir', tag: LogTags.game);
  }

  // 🚀 NOUVEAU : Démarrage manuel par l'utilisateur
  void _startRecording() {
    if (GesturePatternService.isRecording || _currentPhase != DuelPhase.gestureCapture) return;

    _pulseController.repeat(reverse: true);
    _progressController.reset();
    _progressController.forward();

    Logger.debug('🎬 Démarrage enregistrement manuel');
    
    // 🎤 CORRECTION : Démarrer l'écoute vocale EN MÊME TEMPS que le geste
    _startVoiceListening();
    
    GesturePatternService.startRecording(
      onGestureRecorded: _onGestureRecorded,
      onRecordingProgress: (progress) {
        setState(() {
          _recordingProgress = progress;
        });
      },
    );
  }

  // 🚀 NOUVEAU : Arrêt manuel par l'utilisateur  
  void _stopRecording() {
    if (!GesturePatternService.isRecording) return;

    Logger.debug('🛑 Arrêt enregistrement manuel');
    GesturePatternService.stopRecording();
    
    // 🎤 CORRECTION : Arrêter aussi l'écoute vocale
    VoiceService.stopListening();
    
    _pulseController.stop();
    _progressController.stop();
  }

  void _stopGestureCapture() {
    // Cette fonction n'est plus utilisée - le contrôle est maintenant manuel
    // via _startRecording() et _stopRecording()
    Logger.warning(' _stopGestureCapture appelée mais plus utilisée');
  }

  void _onGestureRecorded(GestureData gesture) {
    setState(() {
      _recordedGesture = gesture;
      _currentPhase = DuelPhase.processing;
    });
    
    _processGesture(gesture);
  }

  // 🎯 NOUVELLE MÉTHODE POUR LE SERVICE AVANCÉ
  void _onAdvancedGestureRecorded(GestureSignature signature) {
    setState(() {
      _recordedGesture = signature.toGestureData(); // Conversion pour compatibilité
      _currentPhase = DuelPhase.processing;
    });
    
    _processAdvancedGesture(signature);
  }

  Future<void> _processGesture(GestureData recordedGesture) async {
    Logger.debug('🚀 === NOUVELLE RECONNAISSANCE AMÉLIORÉE ===');
    
    // Reconnaissance du sort le plus proche avec l'algorithme robuste
    double bestScore = 0.0;
    SpellModel? bestMatch;
    
    for (SpellModel spell in _availableSpells) {
      final score = GesturePatternService.compareGestures(recordedGesture, spell.gestureData);
      Logger.debug('🔍 Sort "${spell.name}": Score = ${(score * 100).toStringAsFixed(1)}%');
      if (score > bestScore) {
        bestScore = score;
        bestMatch = spell;
      }
    }
    
          // 🎯 SEUIL MOUVEMENT : 40% minimum - Équilibré maintenant que ça marche
      const double RECOGNITION_THRESHOLD = 0.4;
    
    if (bestScore < RECOGNITION_THRESHOLD) {
      Logger.error(' Aucun sort reconnu (meilleur score: ${(bestScore * 100).toStringAsFixed(1)}%)');
      bestMatch = null;
      _detectedSpellName = 'Geste non reconnu';
    } else {
      Logger.success(' Sort reconnu: "${bestMatch?.name}" (${(bestScore * 100).toStringAsFixed(1)}%)', tag: LogTags.firebase);
    }
    
    // 🔄 NOUVELLE LOGIQUE : Le sort est déjà détecté par la voix
    if (_detectedSpellFromVoice != null) {
      // Sort détecté par incantation, calculer bonus gestuel
      _calculateGestureBonus(recordedGesture);
    } else {
      // Aucun sort détecté par la voix, échec total
      setState(() {
        _gestureAccuracy = bestScore;
        _detectedSpellName = 'Aucune incantation détectée';
        _voiceBonus = false;
      });
    }
    
    // Passer au résultat
    setState(() {
      _currentPhase = DuelPhase.result;
    });
  }

  // 🚀 NOUVELLE MÉTHODE AVEC RECONNAISSANCE AVANCÉE
  Future<void> _processAdvancedGesture(GestureSignature recordedSignature) async {
    Logger.debug('🎯 === RECONNAISSANCE AVANCÉE ===');
    Logger.info(' Features extraites: ${recordedSignature.accelerometerFeatures.length}', tag: LogTags.stats);
    Logger.debug('🏔️ Pics détectés: ${recordedSignature.accelerometerPeaks.length}');
    Logger.debug('⚡ Énergie: ${recordedSignature.accelerometerEnergy.toStringAsFixed(2)}');
    
    // Reconnaissance du sort le plus proche avec l'algorithme avancé
    double bestScore = 0.0;
    SpellModel? bestMatch;
    
    for (SpellModel spell in _availableSpells) {
      // TODO: Convertir GestureData du sort en GestureSignature
      // Pour l'instant, on utilise une approche hybride
      final score = GestureService.compareGestures(recordedSignature.toGestureData(), spell.gestureData);
      Logger.debug('🔍 Sort "${spell.name}": Score = ${(score * 100).toStringAsFixed(1)}%');
      if (score > bestScore) {
        bestScore = score;
        bestMatch = spell;
      }
    }
    
    // 🎯 SEUIL ADAPTATIF basé sur l'énergie du signal
    double RECOGNITION_THRESHOLD = 0.4; // Plus tolérant avec l'analyse avancée
    
    // Ajuster le seuil selon l'énergie du mouvement
    if (recordedSignature.accelerometerEnergy > 20.0) {
      RECOGNITION_THRESHOLD = 0.3; // Plus tolérant pour mouvements énergiques
    } else if (recordedSignature.accelerometerEnergy < 5.0) {
      RECOGNITION_THRESHOLD = 0.6; // Plus strict pour mouvements faibles
    }
    
    Logger.debug('🎯 Seuil adaptatif: ${(RECOGNITION_THRESHOLD * 100).toStringAsFixed(1)}%');
    
    if (bestScore < RECOGNITION_THRESHOLD) {
      Logger.error(' Aucun sort reconnu (meilleur score: ${(bestScore * 100).toStringAsFixed(1)}%)');
      bestMatch = null;
      _detectedSpellName = 'Geste non reconnu';
    } else {
      Logger.success(' Sort reconnu: "${bestMatch?.name}" (${(bestScore * 100).toStringAsFixed(1)}%)', tag: LogTags.firebase);
    }
    
    // 🔄 NOUVELLE LOGIQUE : Le sort est déjà détecté par la voix  
    if (_detectedSpellFromVoice != null) {
      // Sort détecté par incantation, calculer bonus gestuel
      _calculateGestureBonus(recordedSignature.toGestureData());
    } else {
      // Aucun sort détecté par la voix, échec total
      setState(() {
        _gestureAccuracy = bestScore;
        _detectedSpellName = 'Aucune incantation détectée';
        _voiceBonus = false;
      });
    }
    
    // 🎵 Jouer le son basé sur le résultat
    if (_detectedSpellFromVoice != null) {
      // Succès - jouer le son du sort (URL ou fallback) + feedback positif
      if (_detectedSpellFromVoice!.soundFileUrl != null && 
          _detectedSpellFromVoice!.soundFileUrl!.isNotEmpty) {
        // Jouer le son uploadé depuis l'URL
        AudioService().playSoundFromUrl(_detectedSpellFromVoice!.soundFileUrl!);
      } else {
        // Fallback sur l'ancien système par nom
        AudioService().playSpellSound(_detectedSpellFromVoice!.name);
      }
      await Future.delayed(const Duration(milliseconds: 300));
      AudioService().playSFX(SoundType.spellSuccess);
    } else {
      // Échec - feedback négatif
      AudioService().playSFX(SoundType.spellFail);
    }
    
    // Sauvegarder le résultat si c'est un vrai match
    if (!_isTrainingMode && _detectedSpellFromVoice != null) {
      _saveDuelResult();
    }
    
    // Passer au résultat
    setState(() {
      _currentPhase = DuelPhase.result;
    });
  }

  // 🎤 NOUVELLE MÉTHODE - Écoute vocale pour détecter le sort
  Future<void> _startVoiceListening() async {
    if (_availableSpells.isEmpty) return;
    
    setState(() {
      _isVoiceListening = true;
      _voiceStatus = 'Écoute incantation...';
      _voiceBonus = false;
      _recognizedVoice = '';
      _detectedSpellFromVoice = null;
    });

    Logger.debug('🎤 🔄 NOUVELLE LOGIQUE : Écoute vocale pour détecter le sort');

    // Construire la liste de toutes les incantations
    final allIncantations = _availableSpells
        .where((spell) => spell.voiceKeyword.isNotEmpty)
        .map((spell) => spell.voiceKeyword)
        .toList();

    print('🎤 Incantations à écouter: ${allIncantations.join(', ')}');

    final success = await VoiceService.startListening(
      expectedKeywords: allIncantations,
      onResult: (isMatch, recognizedText, matchedKeyword) {
        setState(() {
          _recognizedVoice = recognizedText;
          _isVoiceListening = false;
        });

        if (isMatch && matchedKeyword != null) {
          // Trouver le sort correspondant à l'incantation
          final spell = _availableSpells.firstWhere(
            (s) => s.voiceKeyword == matchedKeyword,
            orElse: () => _availableSpells.first,
          );
          
          setState(() {
            _detectedSpellFromVoice = spell;
            _detectedSpellName = spell.name;
            _voiceStatus = 'Sort détecté par la voix !';
          });

          Logger.success(' Sort détecté par incantation: "${spell.name}"', tag: LogTags.firebase);
        } else {
          setState(() {
            _voiceStatus = 'Aucune incantation reconnue';
          });
          Logger.error(' Aucune incantation reconnue');
        }
      },
      timeoutSeconds: 5,
    );

    if (!success) {
      setState(() {
        _voiceStatus = 'Erreur microphone';
        _isVoiceListening = false;
      });
    }
  }

  // 🎯 NOUVELLE MÉTHODE - Calculer bonus gestuel après détection vocale
  void _calculateGestureBonus(GestureData recordedGesture) {
    if (_detectedSpellFromVoice == null) {
      // Pas de sort détecté par la voix, pas de bonus possible
      setState(() {
        _voiceBonus = false; // Maintenant c'est plutôt "gestureBonus" conceptuellement
      });
      return;
    }

    Logger.debug('🎯 🔄 NOUVELLE LOGIQUE : Calcul bonus gestuel pour "${_detectedSpellFromVoice!.name}"');

    // Comparer le geste avec le sort détecté par la voix
    final gestureScore = GesturePatternService.compareGestures(
      recordedGesture, 
      _detectedSpellFromVoice!.gestureData
    );

    Logger.debug('🎯 Score gestuel: ${(gestureScore * 100).toStringAsFixed(1)}%');

    // Seuil plus tolérant pour le bonus (car c'est optionnel maintenant)
    const double BONUS_THRESHOLD = 0.3;
    final gestureBonus = gestureScore >= BONUS_THRESHOLD;

    setState(() {
      _gestureAccuracy = gestureScore;
      _voiceBonus = gestureBonus; // Réutilisation de la variable pour le bonus gestuel
    });

    Logger.debug('🎯 Bonus gestuel: ${gestureBonus ? "✅ +0.5" : "❌ +0"}');
  }

  /// 💾 NOUVELLE MÉTHODE - Sauvegarder le résultat du duel en temps réel
  Future<void> _saveDuelResult() async {
    if (_isTrainingMode || _detectedSpellFromVoice == null || _currentMatch == null) {
      return;
    }

    try {
      // Créer le round avec les résultats
      final round = RoundModel.fromDuelResult(
        matchId: _currentMatch!.id,
        playerId: widget.playerId,
        spellCast: _detectedSpellFromVoice!.name,
        gestureAccuracy: _gestureAccuracy,
        gestureBonus: _voiceBonus,
      );

      // Sauvegarder dans Firestore
      await FirebaseFirestore.instance
          .collection('rounds')
          .add(round.toFirestore());

      Logger.success(' Résultat sauvegardé: ${round.spellCast} - Score: ${round.totalScore}', tag: LogTags.firebase);

      // Vérifier si le match est terminé et déterminer le gagnant
      await _checkMatchCompletion();
    } catch (e) {
      Logger.error(' Erreur sauvegarde résultat: $e');
      // Ne pas bloquer l'interface en cas d'erreur
    }
  }

  /// 🏆 Vérifier si le match est terminé et déterminer le gagnant
  Future<void> _checkMatchCompletion() async {
    if (_currentMatch == null) return;

    try {
      // Récupérer tous les rounds de ce match
      final roundsSnapshot = await FirebaseFirestore.instance
          .collection('rounds')
          .where('matchId', isEqualTo: 
              FirebaseFirestore.instance.collection('matches').doc(_currentMatch!.id))
          .get();

      final rounds = roundsSnapshot.docs
          .map((doc) => RoundModel.fromFirestore(doc))
          .toList();

      // Calculer les scores par joueur
      final Map<String, double> playerScores = {};
      for (final round in rounds) {
        final playerId = round.playerId.id;
        playerScores[playerId] = (playerScores[playerId] ?? 0.0) + round.totalScore;
      }

      Logger.info(' Scores actuels: $playerScores', tag: LogTags.stats);

      // Vérifier si un joueur a atteint le score requis
      final requiredScore = _currentMatch!.roundsToWin.toDouble();
      String? winnerId;
      
      for (final entry in playerScores.entries) {
        if (entry.value >= requiredScore) {
          winnerId = entry.key;
          break;
        }
      }

      // Si un gagnant est trouvé, terminer le match
      if (winnerId != null) {
        await ArenaService.setMatchWinner(_currentMatch!.id, winnerId);
        
                 if (mounted) {
           final isWinner = winnerId == widget.playerId;
           
           // 🎵 Jouer la séquence audio appropriée
           if (isWinner) {
             AudioService().playVictorySequence();
           } else {
             AudioService().playDefeatSequence();
           }
           
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(
                 isWinner
                     ? '🏆 Félicitations ! Vous avez gagné !'
                     : '😔 Vous avez perdu. Meilleure chance la prochaine fois !',
               ),
               backgroundColor: isWinner ? Colors.green : Colors.orange,
               duration: const Duration(seconds: 5),
             ),
           );
         }

        Logger.game(' Match terminé ! Gagnant: $winnerId', tag: LogTags.match);
      }
    } catch (e) {
      Logger.error(' Erreur vérification fin de match: $e');
    }
  }

  void _resetTraining() {
    setState(() {
      _currentPhase = DuelPhase.waiting;
      _recordedGesture = null;
      _gestureAccuracy = 0.0;
      _detectedSpellName = '';
      _voiceBonus = false;
      _voiceStatus = '';
      _recognizedVoice = '';
      _isVoiceListening = false;
      _detectedSpellFromVoice = null;
      _recordingProgress = 0;
    });
  }

  @override
  void dispose() {
    // _captureTimer?.cancel(); // Plus utilisé avec le contrôle manuel
    _pulseController.dispose();
    _progressController.dispose();
    GestureService.dispose();
    AdvancedGestureService.dispose(); // 🎯 NOUVEAU
    VoiceService.dispose(); // 🎤 NOUVEAU
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Text(
          _isTrainingMode ? 'Entraînement Magique' : _buildDuelTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingMatch && !_isTrainingMode
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Chargement du match...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    // Affichage des joueurs (si match réel)
                    if (!_isTrainingMode) _buildPlayersHeader(),
                    
                    // Phase indicator
                    _buildPhaseIndicator(),
                    const SizedBox(height: 40),

                    // Main content based on phase
                    Expanded(
                      child: _buildPhaseContent(),
                    ),

                    // Boutons de contrôle en bas
                    _buildControlButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhaseIndicator() {
    String phaseText;
    Color phaseColor;
    
    switch (_currentPhase) {
      case DuelPhase.waiting:
        phaseText = _isTrainingMode ? 'Prêt à détecter un sort' : 'En attente';
        phaseColor = Colors.blue;
        break;
      case DuelPhase.gestureCapture:
        phaseText = 'Capture du geste... $_recordingProgress%';
        phaseColor = Colors.red;
        break;
      case DuelPhase.processing:
        if (_voiceStatus == 'Écoute en cours...') {
          phaseText = '🎤 Écoute incantation...';
          phaseColor = Colors.purple;
        } else {
          phaseText = 'Analyse en cours...';
          phaseColor = Colors.amber;
        }
        break;
      case DuelPhase.result:
        phaseText = 'Résultat';
        phaseColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: phaseColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        phaseText,
        style: TextStyle(
          color: phaseColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_currentPhase) {
      case DuelPhase.waiting:
        return _buildWaitingContent();
      case DuelPhase.gestureCapture:
        return _buildGestureCaptureContent();
      case DuelPhase.processing:
        return _buildProcessingContent();
      case DuelPhase.result:
        return _buildResultContent();
    }
  }

  Widget _buildWaitingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_fix_high,
          size: 80,
          color: Colors.blue.shade300,
        ),
        const SizedBox(height: 24),
        const Text(
          'Appuyez sur le bouton et effectuez\nun mouvement magique !',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'L\'app détectera automatiquement\nquel sort vous lancez',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGestureCaptureContent() {
    final isRecording = GesturePatternService.isRecording;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🎯 BOUTON PRINCIPAL - Appuyer et maintenir
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isRecording ? _pulseAnimation.value : 1.0,
              child: GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                onTapCancel: () => _stopRecording(),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isRecording
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isRecording ? Colors.red : Colors.blue)
                            .withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        // 🎯 TITRE DYNAMIQUE
        Text(
          isRecording ? '🎯 ENREGISTREMENT EN COURS' : '🎮 PRÊT À CAPTURER',
          style: TextStyle(
            color: isRecording ? Colors.red : Colors.blue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 🎯 INSTRUCTIONS DYNAMIQUES
        Text(
          isRecording 
              ? 'Effectuez votre mouvement magique${_isVoiceListening ? " et prononcez l\'incantation" : ""}...'
              : 'Maintenez le bouton et faites votre geste',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        
        if (isRecording) ...[
          const SizedBox(height: 16),
          Text(
            '${(_recordingProgress / 1000).toStringAsFixed(1)}s',
            style: TextStyle(
              color: Colors.red.shade300,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // 🎯 BARRE DE PROGRESSION (seulement si enregistrement)
        if (isRecording)
          LinearProgressIndicator(
            backgroundColor: Colors.grey.shade700,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
          ),
      ],
    );
  }

  Widget _buildProcessingContent() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
        ),
        SizedBox(height: 24),
        Text(
          'Analyse du geste...',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResultContent() {
    final isRecognized = _detectedSpellName != 'Geste non reconnu';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isRecognized ? Icons.check_circle : Icons.cancel,
          size: 80,
          color: isRecognized ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 24),
        Text(
          _detectedSpellFromVoice != null ? 'Sort Lancé !' : 'Échec du Sort',
          style: TextStyle(
            color: _detectedSpellFromVoice != null ? Colors.green : Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_detectedSpellFromVoice != null) ...[
          Text(
            _detectedSpellName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Score: ${RoundModel.calculateScore(_gestureAccuracy, _voiceBonus).toStringAsFixed(1)} points',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
            ),
          ),
          if (!_isTrainingMode) ...[
            const SizedBox(height: 8),
            Text(
              '💾 Résultat enregistré',
              style: TextStyle(
                color: Colors.green.shade300,
                fontSize: 14,
              ),
            ),
          ],
          if (_voiceStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '🎤 $_voiceStatus',
              style: TextStyle(
                color: _detectedSpellFromVoice != null ? Colors.green : Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_recognizedVoice.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"$_recognizedVoice"',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_voiceBonus && _detectedSpellFromVoice != null) ...[
              const SizedBox(height: 4),
              const Text(
                '🎯 Bonus gestuel (+0.5)',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (!_isTrainingMode && _detectedSpellFromVoice != null) ...[
              const SizedBox(height: 4),
              Text(
                'Sauvegardé dans Firestore',
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ] else ...[
          Text(
            'Prononcez clairement une incantation',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_currentPhase == DuelPhase.waiting) ...[
            ElevatedButton(
              onPressed: _startGestureCapture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                '🎯 Détecter Sort',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ] else if (_currentPhase == DuelPhase.gestureCapture) ...[
            // Plus de bouton séparé - l'utilisateur contrôle via le bouton principal
          ] else if (_currentPhase == DuelPhase.result) ...[
            ElevatedButton(
              onPressed: _resetTraining,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                '🔄 Tester Autre Sort',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 