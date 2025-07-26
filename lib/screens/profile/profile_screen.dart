import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/stats_service.dart';
import '../../models/match_model.dart';
import '../../services/arena_service.dart';

import '../../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PlayerStats? _playerStats;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPlayerStats();
  }

  Future<void> _loadPlayerStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userProfile?.id;
    
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _currentUserId = userId;
    });

    try {
      final stats = await StatsService.getPlayerStats(userId);
      setState(() {
        _playerStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error(' Erreur chargement stats profil: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Chargement des statistiques...',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlayerStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        // Header Profil
                        _buildProfileHeader(),
                        const SizedBox(height: 40),
                        
                        // Avatar et info utilisateur
                        _buildUserHeader(),
                        const SizedBox(height: 32),
                        
                        // Statistiques détaillées
                        _buildDetailedStats(),
                        const SizedBox(height: 32),
                        
                        // Sorts favoris
                        _buildSpellsStats(),
                        const SizedBox(height: 32),

                        // Historique récent
                        _buildMatchHistory(),
                        const SizedBox(height: 32),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loadPlayerStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit),
                        label: const Text('Éditer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/leaderboard'),
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Classement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
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
          // Icon Profil avec effet
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
              Icons.person,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Titre
          Text(
            'Mon Profil',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Vos statistiques et progression magique',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;
    final stats = _playerStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar avec niveau
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: _getLevelColor(),
                  child: Icon(
                    Icons.auto_fix_high,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${stats?.totalMatches ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Sorcier Inconnu',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getLevelColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getLevelColor()),
              ),
              child: Text(
                stats?.playerLevel ?? 'Apprenti Sorcier',
                style: TextStyle(
                  color: _getLevelColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(context, 'Matchs', '${stats?.totalMatches ?? 0}'),
                _buildStatItem(context, 'Victoires', '${stats?.wins ?? 0}'),
                _buildStatItem(context, 'Défaites', '${stats?.losses ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    final stats = _playerStats;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Statistiques de Combat',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailedStat(context, 'Taux de victoire', '${stats.winRate.toStringAsFixed(1)}%'),
            _buildDetailedStat(context, 'Sorts lancés', '${stats.totalSpellsCast}'),
            _buildDetailedStat(context, 'Score total', '${stats.totalScore.toStringAsFixed(1)} pts'),
            _buildDetailedStat(context, 'Précision moyenne', '${(stats.averageAccuracy * 100).toStringAsFixed(1)}%'),
            _buildDetailedStat(context, 'Bonus gestuels', '${stats.gestureBonus}'),
            if (stats.lastMatchDate != null)
              _buildDetailedStat(context, 'Dernier match', _formatDate(stats.lastMatchDate!)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellsStats() {
    final stats = _playerStats;
    if (stats == null || stats.spellsUsed.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_fix_high, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Sorts Favoris',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.spellsUsed.entries.take(5).map((entry) {
              final spell = entry.key;
              final count = entry.value;
              final accuracy = stats.spellAccuracy[spell] ?? 0.0;
              
              return _buildSpellStat(context, spell, count, accuracy);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellStat(BuildContext context, String spell, int count, double accuracy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.flash_on,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spell,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count fois • ${(accuracy * 100).toStringAsFixed(1)}% précision',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistory() {
    final stats = _playerStats;
    if (stats == null || stats.recentMatches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun match joué',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lancez votre premier duel !',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Historique Récent',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.recentMatches.map((match) => _buildMatchHistoryItem(match)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchHistoryItem(MatchModel match) {
    final isWinner = match.winner?.id == _currentUserId;
    final isFinished = match.status == MatchStatus.finished;
    
    // Déterminer l'adversaire
    final opponentRef = match.player1.id == _currentUserId ? match.player2 : match.player1;
    
    return FutureBuilder<String>(
      future: ArenaService.getUserNameFromRef(opponentRef),
      builder: (context, snapshot) {
        final opponentName = snapshot.data ?? 'Chargement...';
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                isFinished
                    ? (isWinner ? Icons.check_circle : Icons.cancel)
                    : Icons.schedule,
                color: isFinished
                    ? (isWinner ? Colors.green : Colors.red)
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs. $opponentName',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isFinished
                          ? (isWinner ? 'Victoire' : 'Défaite')
                          : 'En cours',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isFinished
                            ? (isWinner ? Colors.green : Colors.red)
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(match.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getLevelColor() {
    final stats = _playerStats;
    if (stats == null) return Colors.grey;
    
    final colorHex = stats.levelColor;
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDetailedStat(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }




} 