import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../../services/match_service.dart';
import '../../widgets/common_widgets.dart';

class LiveTournamentScreen extends StatefulWidget {
  final String tournamentId;
  
  const LiveTournamentScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<LiveTournamentScreen> createState() => _LiveTournamentScreenState();
}

class _LiveTournamentScreenState extends State<LiveTournamentScreen> with TickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService();
  final MatchService _matchService = MatchService();
  
  TournamentModel? _tournament;
  List<BracketMatch> _matches = [];
  bool _isLoading = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTournament();
    _listenToMatches();
  }

  Future<void> _loadTournament() async {
    final tournament = await _tournamentService.getTournamentById(widget.tournamentId);
    if (tournament != null) {
      setState(() => _tournament = tournament);
    }
  }

  void _listenToMatches() {
    _matchService.getMatchesStream(widget.tournamentId).listen((matches) {
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📊 ${_tournament?.name ?? 'Tournoi Live'}'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle), text: 'En cours'),
            Tab(icon: Icon(Icons.pending), text: 'En attente'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Classement'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // En-tête avec progression
        _buildProgressHeader(),
        
        // Contenu par onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveMatches(),
              _buildPendingMatches(),
              _buildStandings(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    if (_tournament == null) return const SizedBox.shrink();
    
    final progress = _matchService.calculateTournamentProgress(_matches);
    final completedMatches = _matches.where((m) => m.isCompleted).length;
    final totalMatches = _matches.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre et statut
          Row(
            children: [
              Expanded(
                child: Text(
                  _tournament!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'EN DIRECT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progression
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression du tournoi',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$completedMatches/$totalMatches',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMatches() {
    final activeMatches = _matches
        .where((m) => m.status == BracketMatchStatus.inProgress)
        .toList();

    if (activeMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun match en cours',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeMatches.length,
      itemBuilder: (context, index) {
        final match = activeMatches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildActiveMatchCard(match),
        );
      },
    );
  }

  Widget _buildActiveMatchCard(BracketMatch match) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.red.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Durée
                  if (match.startedAt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDuration(DateTime.now().difference(match.startedAt!)),
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Joueurs en cours
              Row(
                children: [
                  Expanded(
                    child: _buildLivePlayerCard(
                      playerId: match.player1Id,
                      isLeft: true,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.flash_on,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildLivePlayerCard(
                      playerId: match.player2Id,
                      isLeft: false,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Bouton terminer (pour les admins)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showFinishMatchDialog(match),
                  icon: const Icon(Icons.stop_circle, size: 20),
                  label: const Text('Terminer le match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePlayerCard({String? playerId, required bool isLeft}) {
    final playerName = playerId != null ? 'Joueur ${playerId.substring(0, 8)}' : 'TBD';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person,
            color: Colors.blue.shade600,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            playerName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingMatches() {
    final pendingMatches = _matches
        .where((m) => m.status == BracketMatchStatus.ready)
        .toList();

    if (pendingMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun match en attente',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingMatches.length,
      itemBuilder: (context, index) {
        final match = pendingMatches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildPendingMatchCard(match),
        );
      },
    );
  }

  Widget _buildPendingMatchCard(BracketMatch match) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Joueurs
            Row(
              children: [
                Expanded(
                  child: _buildSimplePlayerCard(match.player1Id),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildSimplePlayerCard(match.player2Id),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Bouton démarrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startMatch(match),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Démarrer le match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePlayerCard(String? playerId) {
    final playerName = playerId != null ? 'Joueur ${playerId.substring(0, 8)}' : 'TBD';
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 16,
            color: playerId != null ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              playerName,
              style: TextStyle(
                fontSize: 12,
                color: playerId != null ? Colors.black87 : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandings() {
    if (_tournament?.type != TournamentType.roundRobin) {
      return const Center(
        child: Text(
          'Classement disponible uniquement\npour les tournois Round Robin',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final standings = _matchService.getRoundRobinStandings(_matches);
    
    if (standings.isEmpty) {
      return const Center(
        child: Text(
          'Aucun résultat disponible',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final playerStats = standings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildStandingCard(playerStats, index + 1),
        );
      },
    );
  }

  Widget _buildStandingCard(Map<String, dynamic> stats, int position) {
    final wins = stats['wins'] as int;
    final losses = stats['losses'] as int;
    final totalScore = stats['totalScore'] as double;
    final matchesPlayed = stats['matchesPlayed'] as int;
    final playerId = stats['playerId'] as String;
    
    Color positionColor;
    if (position == 1) {
      positionColor = Colors.amber;
    } else if (position == 2) {
      positionColor = Colors.grey.shade400;
    } else if (position == 3) {
      positionColor = Colors.orange.shade700;
    } else {
      positionColor = Colors.grey;
    }

    return Card(
      elevation: position <= 3 ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Position
            Container(
              width: 32,
              height: 32,
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
            
            const SizedBox(width: 12),
            
            // Joueur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Joueur ${playerId.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$wins victoires - $losses défaites',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${totalScore.toStringAsFixed(1)} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$matchesPlayed matchs',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Actions
  Future<void> _startMatch(BracketMatch match) async {
    final success = await _matchService.startMatch(match.id);
    if (mounted) {
      if (success) {
        SoundNotification.show(context, message: '▶️ Match démarré !');
      } else {
        SoundNotification.show(context, message: '❌ Erreur lors du démarrage');
      }
    }
  }

  void _showFinishMatchDialog(BracketMatch match) {
    showDialog(
      context: context,
      builder: (context) => _FinishMatchDialog(
        match: match,
        onFinish: (winnerId, winnerScore, loserScore) async {
          final success = await _matchService.finishMatch(
            matchId: match.id,
            winnerId: winnerId,
            winnerScore: winnerScore,
            loserScore: loserScore,
          );
          
          if (mounted) {
            if (success) {
              SoundNotification.show(context, message: '🏆 Match terminé !');
            } else {
              SoundNotification.show(context, message: '❌ Erreur lors de la fin');
            }
          }
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Dialog pour terminer un match
class _FinishMatchDialog extends StatefulWidget {
  final BracketMatch match;
  final Function(String winnerId, double winnerScore, double loserScore) onFinish;
  
  const _FinishMatchDialog({
    required this.match,
    required this.onFinish,
  });

  @override
  State<_FinishMatchDialog> createState() => _FinishMatchDialogState();
}

class _FinishMatchDialogState extends State<_FinishMatchDialog> {
  String? _selectedWinner;
  final _winnerScoreController = TextEditingController();
  final _loserScoreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Terminer ${widget.match.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sélection du gagnant
          Text('Qui a gagné ?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          
          Row(
            children: [
              if (widget.match.player1Id != null)
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Joueur 1'),
                    subtitle: Text(widget.match.player1Id!.substring(0, 8)),
                    value: widget.match.player1Id!,
                    groupValue: _selectedWinner,
                    onChanged: (value) => setState(() => _selectedWinner = value),
                  ),
                ),
              if (widget.match.player2Id != null)
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Joueur 2'),
                    subtitle: Text(widget.match.player2Id!.substring(0, 8)),
                    value: widget.match.player2Id!,
                    groupValue: _selectedWinner,
                    onChanged: (value) => setState(() => _selectedWinner = value),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Scores
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _winnerScoreController,
                  decoration: const InputDecoration(
                    labelText: 'Score gagnant',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _loserScoreController,
                  decoration: const InputDecoration(
                    labelText: 'Score perdant',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _canFinish() ? _finishMatch : null,
          child: const Text('Terminer'),
        ),
      ],
    );
  }

  bool _canFinish() {
    return _selectedWinner != null &&
           _winnerScoreController.text.isNotEmpty &&
           _loserScoreController.text.isNotEmpty;
  }

  void _finishMatch() {
    final winnerScore = double.tryParse(_winnerScoreController.text) ?? 0.0;
    final loserScore = double.tryParse(_loserScoreController.text) ?? 0.0;
    
    widget.onFinish(_selectedWinner!, winnerScore, loserScore);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _winnerScoreController.dispose();
    _loserScoreController.dispose();
    super.dispose();
  }
} 