import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../../services/match_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common_widgets.dart';

class TournamentResultsScreen extends StatefulWidget {
  final String tournamentId;
  
  const TournamentResultsScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentResultsScreen> createState() => _TournamentResultsScreenState();
}

class _TournamentResultsScreenState extends State<TournamentResultsScreen> with TickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService();
  final MatchService _matchService = MatchService();
  
  TournamentModel? _tournament;
  TournamentBracket? _bracket;
  List<Map<String, dynamic>> _rankings = [];
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadTournamentResults();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadTournamentResults() async {
    setState(() => _isLoading = true);
    
    try {
      final tournament = await _tournamentService.getTournamentById(widget.tournamentId);
      final bracket = await _tournamentService.getTournamentBracket(widget.tournamentId);
      
      if (tournament != null && bracket != null) {
        setState(() {
          _tournament = tournament;
          _bracket = bracket;
          _rankings = _calculateRankings(tournament, bracket);
        });
        
        // Démarrer l'animation après le chargement
        _animationController.forward();
      }
    } catch (e) {
      Logger.error('Erreur chargement résultats tournoi', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _calculateRankings(TournamentModel tournament, TournamentBracket bracket) {
    if (tournament.type == TournamentType.roundRobin) {
      return _matchService.getRoundRobinStandings(bracket.matches);
    } else {
      // Pour les tournois à élimination, utiliser les résultats du bracket
      return _calculateEliminationRankings(bracket);
    }
  }

  List<Map<String, dynamic>> _calculateEliminationRankings(TournamentBracket bracket) {
    final rankings = <Map<String, dynamic>>[];
    
    // 1. Champion (gagnant de la finale)
    final finalMatch = bracket.matches.where((m) => m.type == BracketMatchType.final_).firstOrNull;
    if (finalMatch?.winnerId != null) {
      rankings.add({
        'playerId': finalMatch!.winnerId!,
        'position': 1,
        'title': 'Champion',
        'wins': _countWins(finalMatch.winnerId!, bracket.matches),
        'totalScore': _calculateTotalScore(finalMatch.winnerId!, bracket.matches),
        'matches': _countMatches(finalMatch.winnerId!, bracket.matches),
      });
      
      // 2. Vice-champion (perdant de la finale)
      if (finalMatch.loserId != null) {
        rankings.add({
          'playerId': finalMatch.loserId!,
          'position': 2,
          'title': 'Vice-Champion',
          'wins': _countWins(finalMatch.loserId!, bracket.matches),
          'totalScore': _calculateTotalScore(finalMatch.loserId!, bracket.matches),
          'matches': _countMatches(finalMatch.loserId!, bracket.matches),
        });
      }
    }
    
    // 3. Demi-finalistes (perdants des demi-finales)
    final semiMatches = bracket.matches.where((m) => m.type == BracketMatchType.semifinal).toList();
    int position = 3;
    for (final match in semiMatches) {
      if (match.loserId != null && !rankings.any((r) => r['playerId'] == match.loserId)) {
        rankings.add({
          'playerId': match.loserId!,
          'position': position,
          'title': position == 3 ? 'Troisième place' : 'Quatrième place',
          'wins': _countWins(match.loserId!, bracket.matches),
          'totalScore': _calculateTotalScore(match.loserId!, bracket.matches),
          'matches': _countMatches(match.loserId!, bracket.matches),
        });
        position++;
      }
    }
    
    // 4. Autres participants
    final allPlayerIds = <String>{};
    for (final match in bracket.matches) {
      if (match.player1Id != null) allPlayerIds.add(match.player1Id!);
      if (match.player2Id != null) allPlayerIds.add(match.player2Id!);
    }
    
    for (final playerId in allPlayerIds) {
      if (!rankings.any((r) => r['playerId'] == playerId)) {
        rankings.add({
          'playerId': playerId,
          'position': position,
          'title': 'Participant',
          'wins': _countWins(playerId, bracket.matches),
          'totalScore': _calculateTotalScore(playerId, bracket.matches),
          'matches': _countMatches(playerId, bracket.matches),
        });
        position++;
      }
    }
    
    return rankings;
  }

  int _countWins(String playerId, List<BracketMatch> matches) {
    return matches.where((m) => m.winnerId == playerId).length;
  }

  double _calculateTotalScore(String playerId, List<BracketMatch> matches) {
    double totalScore = 0.0;
    for (final match in matches) {
      if (match.player1Id == playerId && match.player1Score != null) {
        totalScore += match.player1Score!;
      } else if (match.player2Id == playerId && match.player2Score != null) {
        totalScore += match.player2Score!;
      }
    }
    return totalScore;
  }

  int _countMatches(String playerId, List<BracketMatch> matches) {
    return matches.where((m) => 
      m.player1Id == playerId || m.player2Id == playerId
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : _tournament == null
              ? _buildErrorState()
              : _buildResultsContent(),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chargement...'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Calcul des résultats...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible d\'afficher les résultats',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade900,
            Colors.purple.shade600,
            Colors.white,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec titre du tournoi
            _buildHeader(),
            
            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Podium des 3 premiers
                    if (_rankings.length >= 3) _buildPodium(),
                    
                    // Classement complet
                    _buildFullRanking(),
                    
                    // Statistiques du tournoi
                    _buildTournamentStats(),
                    
                    // Actions
                    _buildActionButtons(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Icône et retour
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              Icon(
                Icons.emoji_events,
                color: Colors.amber.shade300,
                size: 32,
              ),
              const Spacer(),
              const SizedBox(width: 48), // Équilibrer l'espace
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Titre
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              _tournament!.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Résultats du tournoi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _rankings.take(3).toList();
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Titre podium
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'PODIUM',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Podium visuel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2ème place
                  if (top3.length > 1) _buildPodiumPosition(top3[1], 2),
                  
                  // 1ère place (plus haute)
                  if (top3.isNotEmpty) _buildPodiumPosition(top3[0], 1),
                  
                  // 3ème place
                  if (top3.length > 2) _buildPodiumPosition(top3[2], 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumPosition(Map<String, dynamic> player, int position) {
    Color color;
    double height;
    IconData medalIcon;
    
    switch (position) {
      case 1:
        color = Colors.amber;
        height = 120;
        medalIcon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey.shade400;
        height = 100;
        medalIcon = Icons.workspace_premium;
        break;
      case 3:
        color = Colors.orange.shade700;
        height = 80;
        medalIcon = Icons.workspace_premium;
        break;
      default:
        color = Colors.grey;
        height = 60;
        medalIcon = Icons.star;
    }

    return Column(
      children: [
        // Avatar et médaille
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.3), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            
            // Médaille
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  medalIcon,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Nom
        Text(
          'Joueur ${player['playerId'].substring(0, 8)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Stats
        Text(
          '${player['wins']}V - ${player['totalScore'].toStringAsFixed(1)}pts',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Marche du podium
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$position',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullRanking() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                children: [
                  Icon(Icons.leaderboard, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Classement Complet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Liste des joueurs
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rankings.length,
                itemBuilder: (context, index) {
                  final player = _rankings[index];
                  return _buildRankingCard(player, index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> player, int index) {
    final position = player['position'] as int;
    Color positionColor;
    
    if (position == 1) {
      positionColor = Colors.amber;
    } else if (position == 2) {
      positionColor = Colors.grey;
    } else if (position == 3) {
      positionColor = Colors.orange;
    } else {
      positionColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: position <= 3
            ? LinearGradient(
                colors: [positionColor.withValues(alpha: 0.1), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        border: position <= 3
            ? Border.all(color: positionColor.withValues(alpha: 0.3))
            : Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: positionColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        title: Text(
          'Joueur ${player['playerId'].substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        
        subtitle: Text(
          player['title'] as String,
          style: TextStyle(
            color: positionColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${player['wins']}V',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              '${player['totalScore'].toStringAsFixed(1)} pts',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentStats() {
    if (_tournament == null || _bracket == null) return const SizedBox.shrink();
    
    final totalMatches = _bracket!.matches.length;
    final completedMatches = _bracket!.matches.where((m) => m.isCompleted).length;
    
    return Container(
      margin: const EdgeInsets.all(20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  const Text(
                    'Statistiques du Tournoi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Participants',
                      '${_tournament!.registeredPlayerIds.length}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Matchs joués',
                      '$completedMatches/$totalMatches',
                      Icons.sports_mma,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Type',
                      _getTypeLabel(_tournament!.type),
                      Icons.category,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Durée',
                      _calculateDuration(),
                      Icons.timer,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Voir le bracket
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                '/tournaments/${widget.tournamentId}/bracket',
              ),
              icon: const Icon(Icons.account_tree),
              label: const Text('Revoir le Bracket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Partager les résultats
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _shareResults,
              icon: const Icon(Icons.share),
              label: const Text('Partager les Résultats'),
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  void _shareResults() {
    // TODO: Implémenter le partage des résultats
    SoundNotification.show(context, message: '📤 Fonction de partage bientôt disponible');
  }

  // Utilitaires
  String _getTypeLabel(TournamentType type) {
    switch (type) {
      case TournamentType.singleElimination:
        return 'Élimination';
      case TournamentType.doubleElimination:
        return 'Double Élim.';
      case TournamentType.roundRobin:
        return 'Round Robin';
      case TournamentType.swiss:
        return 'Suisse';
    }
  }

  String _calculateDuration() {
    if (_tournament?.endDate != null) {
      final duration = _tournament!.endDate!.difference(_tournament!.createdAt);
      if (duration.inDays > 0) {
        return '${duration.inDays}j';
      } else if (duration.inHours > 0) {
        return '${duration.inHours}h';
      } else {
        return '${duration.inMinutes}min';
      }
    }
    return 'En cours';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
} 