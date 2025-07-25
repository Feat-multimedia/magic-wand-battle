import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import '../../models/spell_model.dart';
import '../../models/match_model.dart';
import '../../services/spell_service.dart';
import '../../services/gesture_service.dart';
import '../../services/advanced_gesture_service.dart';

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
  
  // Résultats
  double _gestureAccuracy = 0.0;
  String _detectedSpellName = '';
  bool _voiceBonus = false;
  
  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // Timer pour capture automatique
  Timer? _captureTimer;
  int _recordingProgress = 0;

  // 🎯 NOUVEAU: Mode entraînement simplifié
  bool get _isTrainingMode => widget.matchId == 'training';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSpells();
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
      print('Erreur lors du chargement des sorts: $e');
    }
  }

  void _startGestureCapture() {
    setState(() {
      _currentPhase = DuelPhase.gestureCapture;
      _recordingProgress = 0;
    });

    _pulseController.repeat(reverse: true);
    _progressController.reset();
    _progressController.forward();

    // 🎯 RETOUR AU SERVICE SIMPLE QUI MARCHE
    GestureService.startRecording(
      onGestureRecorded: _onGestureRecorded,
      onRecordingProgress: (progress) {
        setState(() {
          _recordingProgress = progress;
        });
      },
    );

    // Auto-stop après 5 secondes
    _captureTimer = Timer(const Duration(seconds: 5), () {
      if (_currentPhase == DuelPhase.gestureCapture) {
        _stopGestureCapture();
      }
    });
  }

  void _stopGestureCapture() {
    _captureTimer?.cancel();
    _pulseController.stop();
    _progressController.stop();
    
    if (GestureService.isRecording) {
      GestureService.stopRecording();
    }
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
    // Reconnaissance du sort le plus proche
    double bestScore = 0.0;
    SpellModel? bestMatch;
    
    for (SpellModel spell in _availableSpells) {
      final score = GestureService.compareGestures(recordedGesture, spell.gestureData);
      print('🔍 Sort "${spell.name}": Score = ${(score * 100).toStringAsFixed(1)}%');
      if (score > bestScore) {
        bestScore = score;
        bestMatch = spell;
      }
    }
    
    // 🎯 SEUIL MINIMUM : 20% de similarité requis (très tolérant pour debug)
    const double RECOGNITION_THRESHOLD = 0.2;
    
    if (bestScore < RECOGNITION_THRESHOLD) {
      print('❌ Aucun sort reconnu (meilleur score: ${(bestScore * 100).toStringAsFixed(1)}%)');
      bestMatch = null;
      _detectedSpellName = 'Geste non reconnu';
    } else {
      print('✅ Sort reconnu: "${bestMatch?.name}" (${(bestScore * 100).toStringAsFixed(1)}%)');
    }
    
    setState(() {
      _gestureAccuracy = bestScore;
      _detectedSpellName = bestMatch?.name ?? 'Geste non reconnu';
    });
    
    // Simulation du bonus vocal (à remplacer par vraie reconnaissance)
    _voiceBonus = bestMatch != null && 
                  bestMatch.voiceKeyword.isNotEmpty && 
                  Random().nextBool();
    
    // Passer au résultat
    setState(() {
      _currentPhase = DuelPhase.result;
    });
  }

  // 🚀 NOUVELLE MÉTHODE AVEC RECONNAISSANCE AVANCÉE
  Future<void> _processAdvancedGesture(GestureSignature recordedSignature) async {
    print('🎯 === RECONNAISSANCE AVANCÉE ===');
    print('📊 Features extraites: ${recordedSignature.accelerometerFeatures.length}');
    print('🏔️ Pics détectés: ${recordedSignature.accelerometerPeaks.length}');
    print('⚡ Énergie: ${recordedSignature.accelerometerEnergy.toStringAsFixed(2)}');
    
    // Reconnaissance du sort le plus proche avec l'algorithme avancé
    double bestScore = 0.0;
    SpellModel? bestMatch;
    
    for (SpellModel spell in _availableSpells) {
      // TODO: Convertir GestureData du sort en GestureSignature
      // Pour l'instant, on utilise une approche hybride
      final score = GestureService.compareGestures(recordedSignature.toGestureData(), spell.gestureData);
      print('🔍 Sort "${spell.name}": Score = ${(score * 100).toStringAsFixed(1)}%');
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
    
    print('🎯 Seuil adaptatif: ${(RECOGNITION_THRESHOLD * 100).toStringAsFixed(1)}%');
    
    if (bestScore < RECOGNITION_THRESHOLD) {
      print('❌ Aucun sort reconnu (meilleur score: ${(bestScore * 100).toStringAsFixed(1)}%)');
      bestMatch = null;
      _detectedSpellName = 'Geste non reconnu';
    } else {
      print('✅ Sort reconnu: "${bestMatch?.name}" (${(bestScore * 100).toStringAsFixed(1)}%)');
    }
    
    setState(() {
      _gestureAccuracy = bestScore;
      _detectedSpellName = bestMatch?.name ?? 'Geste non reconnu';
    });
    
    // Simulation du bonus vocal (à remplacer par vraie reconnaissance)
    _voiceBonus = bestMatch != null && 
                  bestMatch.voiceKeyword.isNotEmpty && 
                  Random().nextBool();
    
    // Passer au résultat
    setState(() {
      _currentPhase = DuelPhase.result;
    });
  }

  void _resetTraining() {
    setState(() {
      _currentPhase = DuelPhase.waiting;
      _recordedGesture = null;
      _gestureAccuracy = 0.0;
      _detectedSpellName = '';
      _voiceBonus = false;
      _recordingProgress = 0;
    });
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    GestureService.dispose();
    AdvancedGestureService.dispose(); // 🎯 NOUVEAU
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Text(
          _isTrainingMode ? 'Entraînement Magique' : 'Duel Magique',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
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
        phaseText = 'Analyse en cours...';
        phaseColor = Colors.amber;
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        const Text(
          '🎯 ENREGISTREMENT EN COURS',
          style: TextStyle(
            color: Colors.red,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Effectuez votre mouvement magique...',
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: _recordingProgress / 100,
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
          isRecognized ? 'Sort Détecté !' : 'Aucun Sort Reconnu',
          style: TextStyle(
            color: isRecognized ? Colors.green : Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (isRecognized) ...[
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
            'Précision: ${(_gestureAccuracy * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
            ),
          ),
          if (_voiceBonus) ...[
            const SizedBox(height: 8),
            const Text(
              '🎤 Bonus vocal (+0.5)',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
              ),
            ),
          ],
        ] else ...[
          Text(
            'Essayez un mouvement plus distinct',
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
            ElevatedButton(
              onPressed: _stopGestureCapture,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                '⏹️ Arrêter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
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