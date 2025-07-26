import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common_widgets.dart';

class BracketViewerScreen extends StatefulWidget {
  final String tournamentId;
  
  const BracketViewerScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<BracketViewerScreen> createState() => _BracketViewerScreenState();
}

class _BracketViewerScreenState extends State<BracketViewerScreen> {
  final TournamentService _tournamentService = TournamentService();
  TournamentModel? _tournament;
  TournamentBracket? _bracket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournamentData();
  }

  Future<void> _loadTournamentData() async {
    setState(() => _isLoading = true);
    try {
      final tournament = await _tournamentService.getTournamentById(widget.tournamentId);
      final bracket = await _tournamentService.getTournamentBracket(widget.tournamentId);
      
      setState(() {
        _tournament = tournament;
        _bracket = bracket;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erreur chargement bracket', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🏆 ${_tournament?.name ?? 'Bracket'}'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournamentData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBracketContent(),
    );
  }

  Widget _buildBracketContent() {
    if (_tournament == null || _bracket == null) {
      return Center(
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
              'Impossible de charger le bracket',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTournamentData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // En-tête avec infos du tournoi
        _buildTournamentHeader(),
        
        // Bracket principal
        Expanded(
          child: _buildBracketView(),
        ),
      ],
    );
  }

  Widget _buildTournamentHeader() {
    final tournament = _tournament!;
    final bracket = _bracket!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom et statut
          Row(
            children: [
              Expanded(
                child: Text(
                  tournament.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(tournament.status),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Statistiques
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.people,
                label: 'Participants',
                value: '${tournament.registeredPlayerIds.length}',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.sports_mma,
                label: 'Matchs',
                value: '${bracket.matches.length}',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                label: 'Terminés',
                value: '${bracket.completedMatches.length}',
                color: Colors.orange,
              ),
              if (bracket.championId != null)
                _buildStatItem(
                  icon: Icons.emoji_events,
                  label: 'Champion',
                  value: 'Déterminé',
                  color: Colors.purple,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case TournamentStatus.inProgress:
        color = Colors.orange;
        label = 'En cours';
        icon = Icons.play_circle;
        break;
      case TournamentStatus.finished:
        color = Colors.purple;
        label = 'Terminé';
        icon = Icons.emoji_events;
        break;
      default:
        color = Colors.grey;
        label = 'Inconnu';
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
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
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBracketView() {
    final bracket = _bracket!;
    final tournament = _tournament!;

    switch (tournament.type) {
      case TournamentType.singleElimination:
        return _buildSingleEliminationBracket(bracket);
      case TournamentType.roundRobin:
        return _buildRoundRobinBracket(bracket);
      default:
        return _buildGenericBracket(bracket);
    }
  }

  Widget _buildSingleEliminationBracket(TournamentBracket bracket) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Bracket Élimination Directe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            
            // Bracket par rounds
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(bracket.totalRounds, (roundIndex) {
                final round = roundIndex + 1;
                final roundMatches = bracket.getMatchesForRound(round);
                
                return Column(
                  children: [
                    // En-tête du round
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Text(
                        _getRoundTitle(round, bracket.totalRounds),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    
                    // Matches du round
                    Column(
                      children: roundMatches.map((match) => 
                        Container(
                          margin: const EdgeInsets.only(bottom: 12, right: 16),
                          child: _buildMatchCard(match),
                        )
                      ).toList(),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundRobinBracket(TournamentBracket bracket) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            'Classement Round Robin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des matches
          Column(
            children: bracket.matches.map((match) => 
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: _buildMatchCard(match),
              )
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericBracket(TournamentBracket bracket) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: bracket.matches.map((match) => 
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: _buildMatchCard(match),
          )
        ).toList(),
      ),
    );
  }

  Widget _buildMatchCard(BracketMatch match) {
    final isCompleted = match.isCompleted;
    final hasWinner = match.hasWinner;
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du match
          Row(
            children: [
              Expanded(
                child: Text(
                  match.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Joueurs
          _buildPlayerSlot(
            playerId: match.player1Id,
            score: match.player1Score,
            isWinner: hasWinner && match.winnerId == match.player1Id,
            isCompleted: isCompleted,
          ),
          
          const SizedBox(height: 4),
          
          // VS
          Text(
            'VS',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          _buildPlayerSlot(
            playerId: match.player2Id,
            score: match.player2Score,
            isWinner: hasWinner && match.winnerId == match.player2Id,
            isCompleted: isCompleted,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot({
    String? playerId,
    double? score,
    bool isWinner = false,
    bool isCompleted = false,
  }) {
    final playerName = playerId != null ? 'Joueur ${playerId.substring(0, 8)}' : 'TBD';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isWinner 
          ? Colors.green.withValues(alpha: 0.1) 
          : playerId != null 
            ? Colors.blue.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isWinner 
            ? Colors.green 
            : playerId != null 
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Icône joueur
          Icon(
            isWinner ? Icons.emoji_events : Icons.person,
            size: 14,
            color: isWinner 
              ? Colors.green 
              : playerId != null 
                ? Colors.blue 
                : Colors.grey,
          ),
          
          const SizedBox(width: 6),
          
          // Nom joueur
          Expanded(
            child: Text(
              playerName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: playerId != null ? Colors.black87 : Colors.grey.shade500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Score
          if (score != null && isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isWinner ? Colors.green : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 10,
                  color: isWinner ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getRoundTitle(int round, int totalRounds) {
    if (round == totalRounds) {
      return 'FINALE';
    } else if (round == totalRounds - 1) {
      return 'DEMI-FINALE';
    } else {
      return 'ROUND $round';
    }
  }
} 