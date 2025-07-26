import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/game_master_service.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../models/round_model.dart';

class GameMasterScreen extends StatefulWidget {
  const GameMasterScreen({super.key});

  @override
  State<GameMasterScreen> createState() => _GameMasterScreenState();
}

class _GameMasterScreenState extends State<GameMasterScreen> {
  @override
  void dispose() {
    GameMasterService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Game Master'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () => context.push('/projection'),
            tooltip: 'Mode Projection',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: GameMasterService.refreshData,
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
                // Header Game Master
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
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Icon Game Master avec effet
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.games,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Titre
                      Text(
                        'Game Master Dashboard',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Surveillez et contrôlez les duels en temps réel',
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
                
                // Statistiques globales
                _buildEventStatsSection(),
                const SizedBox(height: 32),
                
                // Matchs en direct
                _buildLiveMatchesSection(),
                const SizedBox(height: 32),
                
                // Actions rapides
                _buildQuickActionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventStatsSection() {
    return Container(
      padding: const EdgeInsets.all(32),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Statistiques de l\'Événement',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          StreamBuilder<EventStats>(
            stream: GameMasterService.getEventStatsStream(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? EventStats();
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Matchs Actifs',
                    '${stats.activeMatches}',
                    Icons.sports_esports,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Matchs Terminés',
                    '${stats.completedMatches}',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Joueurs Total',
                    '${stats.totalPlayers}',
                    Icons.people,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    'Sorts Lancés',
                    '${stats.totalSpellsCast}',
                    Icons.auto_fix_high,
                    Colors.orange,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchesSection() {
    return Container(
      padding: const EdgeInsets.all(32),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.live_tv, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Matchs en Direct',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<List<LiveMatchData>>(
            stream: GameMasterService.getLiveMatchesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              
              final liveMatches = snapshot.data ?? [];
              
              if (liveMatches.isEmpty) {
                return _buildEmptyMatchesState();
              }
              
              return Column(
                children: liveMatches.map((liveData) => 
                  _buildLiveMatchCard(liveData)
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMatchesState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sports_esports_outlined,
              size: 48,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun match en cours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les matchs actifs apparaîtront ici en temps réel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(LiveMatchData liveData) {
    final match = liveData.match;
    final isInProgress = match.status == MatchStatus.inProgress;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInProgress 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInProgress 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // En-tête du match
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isInProgress ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  liveData.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Best of ${match.roundsToWin}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Joueurs et scores
          Row(
            children: [
              // Joueur 1
              Expanded(
                child: _buildPlayerInfo(
                  liveData.player1,
                  liveData.currentScores[match.player1.id] ?? 0.0,
                  liveData.leadingPlayer == match.player1.id,
                ),
              ),
              
              // VS au centre
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              
              // Joueur 2
              Expanded(
                child: _buildPlayerInfo(
                  liveData.player2,
                  liveData.currentScores[match.player2.id] ?? 0.0,
                  liveData.leadingPlayer == match.player2.id,
                ),
              ),
            ],
          ),
          
          if (liveData.rounds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Dernière action: ${_formatLastAction(liveData.rounds.last)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Actions
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _projectMatch(liveData),
                  icon: const Icon(Icons.cast, size: 16),
                  label: const Text('Projeter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewMatchDetails(liveData),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Détails'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(UserModel player, double score, bool isLeading) {
    return Column(
      children: [
                 CircleAvatar(
           backgroundColor: isLeading ? const Color(0xFFFFD700) : Colors.grey,
          child: Text(
            player.displayName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          player.displayName,
                     style: TextStyle(
             color: isLeading ? const Color(0xFFFFD700) : Colors.white,
            fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${score.toStringAsFixed(1)} pts',
                     style: TextStyle(
             color: isLeading ? const Color(0xFFFFD700) : Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Actions Rapides',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/admin/arenas'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle Arène'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/projection'),
                  icon: const Icon(Icons.cast),
                  label: const Text('Mode Projection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/leaderboard'),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Classements'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastAction(RoundModel round) {
    final timeAgo = DateTime.now().difference(round.timestamp);
    final timeString = timeAgo.inMinutes > 0 
        ? 'il y a ${timeAgo.inMinutes}min'
        : 'il y a ${timeAgo.inSeconds}s';
    
    return '${round.spellCast} (${round.totalScore} pts) - $timeString';
  }

  void _projectMatch(LiveMatchData liveData) {
    // Navigation vers la projection avec ce match spécifique
    context.push('/projection/${liveData.match.id}');
  }

  void _viewMatchDetails(LiveMatchData liveData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Match ID: ${liveData.match.id}'),
            Text('Statut: ${liveData.status}'),
            Text('Rounds joués: ${liveData.rounds.length}'),
            Text('Créé: ${liveData.match.createdAt}'),
            const SizedBox(height: 12),
            const Text('Scores actuels:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...liveData.currentScores.entries.map((entry) {
              final playerName = entry.key == liveData.match.player1.id 
                  ? liveData.player1.displayName
                  : liveData.player2.displayName;
              return Text('$playerName: ${entry.value.toStringAsFixed(1)} pts');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
} 