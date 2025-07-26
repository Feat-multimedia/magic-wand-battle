import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/game_master_service.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';


class ProjectionScreen extends StatefulWidget {
  final String? specificMatchId;
  
  const ProjectionScreen({super.key, this.specificMatchId});

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen>
    with TickerProviderStateMixin {
  LiveMatchData? _featuredMatch;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _loadFeaturedMatch();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    GameMasterService.dispose();
    super.dispose();
  }

  Future<void> _loadFeaturedMatch() async {
    if (widget.specificMatchId != null) {
      // Charger un match spécifique (depuis le Game Master)
      // Pour l'instant, on utilise le match featured
      final match = await GameMasterService.getFeaturedMatch();
      setState(() => _featuredMatch = match);
    } else {
      // Charger le match le plus intéressant automatiquement
      final match = await GameMasterService.getFeaturedMatch();
      setState(() => _featuredMatch = match);
    }
    
    if (_featuredMatch != null) {
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Mode Projection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeaturedMatch,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Header Projection
                Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Icon Projection avec effet
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEF4444),
                              Color(0xFFF97316),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.cast,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Titre
                      Text(
                        'Mode Projection',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _featuredMatch != null 
                            ? 'Duel en cours entre ${_featuredMatch!.player1.displayName} et ${_featuredMatch!.player2.displayName}'
                            : 'En attente d\'un duel à projeter...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          color: const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Contenu principal
                if (_featuredMatch != null)
                  _buildMatchDisplay(_featuredMatch!)
                else
                  _buildWaitingScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildWaitingScreen() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_esports,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            'MAGIC WAND BATTLE',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 48,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'En attente d\'un duel...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF64748B),
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.live_tv, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 8),
                Text(
                  'MODE PROJECTION ACTIF',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDisplay(LiveMatchData liveData) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideController.value)),
          child: Opacity(
            opacity: _slideController.value,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  // Header avec titre du match
                  _buildMatchHeader(liveData),
                  const SizedBox(height: 40),
                  
                  // Score board principal
                  Expanded(
                    flex: 2,
                    child: _buildScoreBoard(liveData),
                  ),
                  const SizedBox(height: 30),
                  
                  // Dernière action et stats
                  Expanded(
                    flex: 1,
                    child: _buildLastActionAndStats(liveData),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchHeader(LiveMatchData liveData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MAGIC WAND BATTLE',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              letterSpacing: 2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(liveData.match.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.3),
                      child: Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  liveData.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'BEST OF ${liveData.match.roundsToWin}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(LiveMatchData liveData) {
    final player1Score = liveData.currentScores[liveData.match.player1.id] ?? 0.0;
    final player2Score = liveData.currentScores[liveData.match.player2.id] ?? 0.0;
    final isPlayer1Leading = liveData.leadingPlayer == liveData.match.player1.id;
    final isPlayer2Leading = liveData.leadingPlayer == liveData.match.player2.id;

    return Row(
      children: [
        // Joueur 1
        Expanded(
          child: _buildPlayerCard(
            liveData.player1,
            player1Score,
            isPlayer1Leading,
            true, // Aligné à gauche
          ),
        ),
        
        // VS au centre
        Container(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.2),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.8),
                            Colors.orange.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Joueur 2
        Expanded(
          child: _buildPlayerCard(
            liveData.player2,
            player2Score,
            isPlayer2Leading,
            false, // Aligné à droite
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(UserModel player, double score, bool isLeading, bool isLeft) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLeading 
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF374151), const Color(0xFF4B5563)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLeading 
              ? const Color(0xFFFFD700)
              : Colors.white.withValues(alpha: 0.2),
          width: 3,
        ),
        boxShadow: isLeading 
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isLeading 
                    ? [Colors.white, Colors.grey.shade200]
                    : [Colors.grey.shade600, Colors.grey.shade800],
              ),
              border: Border.all(
                color: isLeading ? const Color(0xFFFFD700) : Colors.white,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                player.displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: isLeading ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Nom du joueur
          Text(
            player.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isLeading ? Colors.black : Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          
          // Score
          Text(
            '${score.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: isLeading ? Colors.black : Colors.white,
            ),
          ),
          Text(
            'POINTS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isLeading ? Colors.black54 : Colors.white70,
              letterSpacing: 2,
            ),
          ),
          
          // Indicateur de leader
          if (isLeading) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.black, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'EN TÊTE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLastActionAndStats(LiveMatchData liveData) {
    return Row(
      children: [
        // Dernière action
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DERNIÈRE ACTION',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (liveData.rounds.isNotEmpty) ...[
                  Text(
                    liveData.rounds.last.spellCast,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${liveData.rounds.last.totalScore} points - ${_formatTimeAgo(liveData.rounds.last.timestamp)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Aucune action encore...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        
        // Stats rapides
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.purple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'STATS',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  'Rounds: ${liveData.rounds.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Durée: ${_getMatchDuration(liveData.match.createdAt)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.pending:
        return Colors.orange;
      case MatchStatus.inProgress:
        return Colors.green;
      case MatchStatus.finished:
        return Colors.blue;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes}min';
    } else {
      return 'Il y a ${diff.inSeconds}s';
    }
  }

  String _getMatchDuration(DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

 