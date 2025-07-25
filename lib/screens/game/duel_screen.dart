import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import '../../models/spell_model.dart';
import '../../models/match_model.dart';
import '../../services/spell_service.dart';
import '../../services/gesture_service.dart';

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
  // Game State
  DuelPhase _currentPhase = DuelPhase.waiting;
  int _countdown = 3;
  List<SpellModel> _availableSpells = [];
  SpellModel? _selectedSpell;
  GestureData? _recordedGesture;
  
  // Animations
  late AnimationController _countdownController;
  late AnimationController _gestureController;
  late AnimationController _resultController;
  
  late Animation<double> _countdownAnimation;
  late Animation<double> _gestureScale;
  late Animation<Color?> _gestureColor;
  
  // Timers
  Timer? _countdownTimer;
  Timer? _phaseTimer;
  
  // Results
  String? _detectedSpellName;
  double _gestureAccuracy = 0.0;
  bool _voiceBonus = false;
  DuelResult? _roundResult;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSpells();
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _gestureController.dispose();
    _resultController.dispose();
    _countdownTimer?.cancel();
    _phaseTimer?.cancel();
    GestureService.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _gestureController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _countdownAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.elasticOut),
    );
    
    _gestureScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _gestureController, curve: Curves.easeInOut),
    );
    
    _gestureColor = ColorTween(
      begin: Colors.blue.shade400,
      end: Colors.red.shade400,
    ).animate(_gestureController);
  }

  Future<void> _loadSpells() async {
    try {
      final spells = await SpellService.getAllSpells();
      setState(() {
        _availableSpells = spells;
      });
      _startDuel();
    } catch (e) {
      _showError('Erreur de chargement des sorts: $e');
    }
  }

  void _startDuel() {
    setState(() {
      _currentPhase = DuelPhase.countdown;
      _countdown = 3;
    });
    
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });
      
      _countdownController.forward().then((_) {
        _countdownController.reset();
      });
      
      if (_countdown <= 0) {
        timer.cancel();
        _startSpellSelection();
      }
    });
  }

  void _startSpellSelection() {
    setState(() {
      _currentPhase = DuelPhase.spellSelection;
      _selectedSpell = null;
    });
    
    // 10 secondes pour choisir un sort
    _phaseTimer = Timer(const Duration(seconds: 10), () {
      if (_selectedSpell == null) {
        _selectRandomSpell();
      }
      _startGestureCapture();
    });
  }

  void _selectSpell(SpellModel spell) {
    if (_currentPhase != DuelPhase.spellSelection) return;
    
    setState(() {
      _selectedSpell = spell;
    });
    
    _phaseTimer?.cancel();
    
    // Délai court puis passage à la capture
    Timer(const Duration(milliseconds: 500), () {
      _startGestureCapture();
    });
  }

  void _selectRandomSpell() {
    if (_availableSpells.isNotEmpty) {
      final random = Random();
      setState(() {
        _selectedSpell = _availableSpells[random.nextInt(_availableSpells.length)];
      });
    }
  }

  void _startGestureCapture() {
    setState(() {
      _currentPhase = DuelPhase.gestureCapture;
      _recordedGesture = null;
      _detectedSpellName = null;
      _gestureAccuracy = 0.0;
    });
    
    _gestureController.repeat(reverse: true);
    
    GestureService.startRecording(
      onGestureRecorded: _onGestureRecorded,
      maxDurationMs: 3000,
    );
    
    // Auto-stop après 3 secondes
    _phaseTimer = Timer(const Duration(seconds: 3), () {
      GestureService.stopRecording();
    });
  }

  void _onGestureRecorded(GestureData gesture) {
    _gestureController.stop();
    _gestureController.reset();
    
    setState(() {
      _recordedGesture = gesture;
      _currentPhase = DuelPhase.processing;
    });
    
    _processGesture(gesture);
  }

  Future<void> _processGesture(GestureData recordedGesture) async {
    // Reconnaissance du sort le plus proche
    double bestScore = 0.0;
    SpellModel? bestMatch;
    
    for (SpellModel spell in _availableSpells) {
      final score = GestureService.compareGestures(recordedGesture, spell.gestureData);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = spell;
      }
    }
    
    setState(() {
      _gestureAccuracy = bestScore;
      _detectedSpellName = bestMatch?.name ?? 'Aucun';
    });
    
    // Simulation du bonus vocal (à remplacer par vraie reconnaissance)
    _voiceBonus = _selectedSpell != null && 
                  _selectedSpell!.voiceKeyword.isNotEmpty && 
                  Random().nextBool();
    
    // Calculer le résultat
    _calculateResult(bestMatch, bestScore);
  }

  void _calculateResult(SpellModel? detectedSpell, double accuracy) {
    bool spellMatches = detectedSpell != null && 
                       _selectedSpell != null && 
                       detectedSpell.id == _selectedSpell!.id;
    
    double finalScore = 0.0;
    
    if (spellMatches && accuracy > 0.6) { // Seuil minimum de 60%
      finalScore = accuracy;
      if (_voiceBonus) {
        finalScore += 0.5; // Bonus vocal
        finalScore = finalScore.clamp(0.0, 1.0);
      }
    }
    
    setState(() {
      _roundResult = DuelResult(
        spellUsed: _selectedSpell?.name ?? 'Aucun',
        detectedSpell: detectedSpell?.name ?? 'Aucun',
        accuracy: accuracy,
        voiceBonus: _voiceBonus,
        finalScore: finalScore,
        success: finalScore > 0.6,
      );
      _currentPhase = DuelPhase.result;
    });
    
    _resultController.forward();
    
    // Afficher le résultat pendant 3 secondes
    Timer(const Duration(seconds: 3), () {
      _resetForNextRound();
    });
  }

  void _resetForNextRound() {
    setState(() {
      _currentPhase = DuelPhase.waiting;
      _selectedSpell = null;
      _recordedGesture = null;
      _detectedSpellName = null;
      _gestureAccuracy = 0.0;
      _voiceBonus = false;
      _roundResult = null;
    });
    
    _resultController.reset();
    _countdownController.reset();
    _gestureController.reset();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text('Duel Magique', style: TextStyle(color: Colors.white)),
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
              
              // Available spells (only during selection)
              if (_currentPhase == DuelPhase.spellSelection)
                _buildSpellSelection(),
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
        phaseText = 'En attente...';
        phaseColor = Colors.grey;
        break;
      case DuelPhase.countdown:
        phaseText = 'Préparez-vous !';
        phaseColor = Colors.orange;
        break;
      case DuelPhase.spellSelection:
        phaseText = 'Choisissez votre sort';
        phaseColor = Colors.blue;
        break;
      case DuelPhase.gestureCapture:
        phaseText = 'Effectuez le mouvement !';
        phaseColor = Colors.red;
        break;
      case DuelPhase.processing:
        phaseText = 'Analyse...';
        phaseColor = Colors.purple;
        break;
      case DuelPhase.result:
        phaseText = 'Résultat';
        phaseColor = _roundResult?.success == true ? Colors.green : Colors.red;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: phaseColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phaseColor, width: 2),
      ),
      child: Text(
        phaseText,
        style: TextStyle(
          color: phaseColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_currentPhase) {
      case DuelPhase.countdown:
        return _buildCountdown();
      case DuelPhase.spellSelection:
        return _buildSpellSelectionPrompt();
      case DuelPhase.gestureCapture:
        return _buildGestureCapture();
      case DuelPhase.processing:
        return _buildProcessing();
      case DuelPhase.result:
        return _buildResult();
      default:
        return _buildWaiting();
    }
  }

  Widget _buildCountdown() {
    return AnimatedBuilder(
      animation: _countdownAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _countdownAnimation.value,
          child: Text(
            _countdown > 0 ? _countdown.toString() : 'GO!',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w900,
              color: _countdown > 0 ? Colors.orange : Colors.green,
              shadows: [
                Shadow(
                  color: (_countdown > 0 ? Colors.orange : Colors.green).withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpellSelectionPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.auto_fix_high,
          size: 80,
          color: Colors.blue.shade400,
        ),
        const SizedBox(height: 20),
        Text(
          'Sélectionnez votre sort',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade200,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vous avez 10 secondes',
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildGestureCapture() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_selectedSpell != null) ...[
          Text(
            _selectedSpell!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mot magique: "${_selectedSpell!.voiceKeyword}"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 40),
        ],
        
        AnimatedBuilder(
          animation: _gestureColor,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _gestureScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _gestureScale.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _gestureColor.value?.withValues(alpha: 0.3) ?? Colors.red.withValues(alpha: 0.3),
                          _gestureColor.value ?? Colors.red,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gestureColor.value?.withValues(alpha: 0.5) ?? Colors.red.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gesture,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        const SizedBox(height: 40),
        Text(
          'Effectuez le mouvement maintenant !',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade200,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation(Colors.purple.shade400),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Analyse du mouvement...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.purple.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (_roundResult == null) return const SizedBox();
    
    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, child) {
        return Transform.scale(
          scale: _resultController.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success/Failure Icon
              Icon(
                _roundResult!.success ? Icons.check_circle : Icons.cancel,
                size: 100,
                color: _roundResult!.success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              
              // Result text
              Text(
                _roundResult!.success ? 'RÉUSSI !' : 'ÉCHEC',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _roundResult!.success ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 30),
              
              // Details
              _buildResultDetails(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultDetails() {
    if (_roundResult == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _roundResult!.success ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildResultRow('Sort visé:', _roundResult!.spellUsed),
          _buildResultRow('Sort détecté:', _roundResult!.detectedSpell),
          _buildResultRow('Précision:', '${(_roundResult!.accuracy * 100).toInt()}%'),
          if (_roundResult!.voiceBonus)
            _buildResultRow('Bonus vocal:', '+0.5 pts', color: Colors.amber),
          const SizedBox(height: 10),
          _buildResultRow(
            'Score final:',
            '${(_roundResult!.finalScore * 100).toInt()}%',
            color: _roundResult!.success ? Colors.green : Colors.red,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? color, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 18 : 16,
              color: Colors.grey.shade300,
              fontWeight: isLarge ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 20 : 16,
              color: color ?? Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.hourglass_empty,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 20),
        Text(
          'En attente du début du duel...',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildSpellSelection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableSpells.length,
        itemBuilder: (context, index) {
          final spell = _availableSpells[index];
          final isSelected = _selectedSpell?.id == spell.id;
          
          return GestureDetector(
            onTap: () => _selectSpell(spell),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.blue.shade600
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: Colors.blue, width: 3)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    color: isSelected ? Colors.white : Colors.grey.shade400,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spell.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum DuelPhase {
  waiting,
  countdown,
  spellSelection,
  gestureCapture,
  processing,
  result,
}

class DuelResult {
  final String spellUsed;
  final String detectedSpell;
  final double accuracy;
  final bool voiceBonus;
  final double finalScore;
  final bool success;

  DuelResult({
    required this.spellUsed,
    required this.detectedSpell,
    required this.accuracy,
    required this.voiceBonus,
    required this.finalScore,
    required this.success,
  });
} 