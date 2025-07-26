import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/stats_service.dart';

import '../../utils/logger.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<PlayerRanking> _rankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() => _isLoading = true);
    
    try {
      final rankings = await StatsService.getGlobalRanking(limit: 20);
      setState(() {
        _rankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error(' Erreur chargement classement: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Classement Global'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRankings,
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
                // Header Classement
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
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Icon Classement avec effet
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFEF4444),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Titre
                      Text(
                        'Classement Global',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Les meilleurs sorciers de Magic Wand Battle',
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
                
                // Contenu du classement
                Container(
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
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Chargement du classement...',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : _rankings.isEmpty
                          ? _buildEmptyState()
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.leaderboard, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Top ${_rankings.length} Joueurs',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ..._rankings.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final ranking = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildRankingCard(ranking, index + 1),
                                  );
                                }).toList(),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune statistique disponible',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jouez des matchs pour apparaître dans le classement',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(PlayerRanking ranking, int position) {
    final isTop3 = position <= 3;
    final user = ranking.user;
    final stats = ranking.stats;

    return Container(
      decoration: BoxDecoration(
        color: isTop3 
            ? _getTopRankColor(position).withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop3 
              ? _getTopRankColor(position).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: isTop3 ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Position et médaille
            _buildPositionBadge(position),
            const SizedBox(width: 16),
            
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getLevelColor(stats),
              child: Text(
                user.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Informations du joueur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.playerLevel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getLevelColor(stats),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip('${stats.wins}V', const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildStatChip('${stats.losses}D', const Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      _buildStatChip('${stats.winRate.toStringAsFixed(0)}%', const Color(0xFF3B82F6)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Score total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${ranking.score.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isTop3 ? _getTopRankColor(position) : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionBadge(int position) {
    final isTop3 = position <= 3;
    
    if (isTop3) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getTopRankColor(position),
              _getTopRankColor(position).withValues(alpha: 0.7),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getTopRankColor(position).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _getTopRankIcon(position),
          color: Colors.white,
          size: 20,
        ),
      );
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF64748B).withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF64748B).withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          '$position',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTopRankColor(int position) {
    switch (position) {
      case 1: return const Color(0xFFFFD700); // Or
      case 2: return const Color(0xFFC0C0C0); // Argent
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return Colors.grey;
    }
  }

  IconData _getTopRankIcon(int position) {
    switch (position) {
      case 1: return Icons.emoji_events; // Trophée
      case 2: return Icons.military_tech; // Médaille
      case 3: return Icons.workspace_premium; // Badge
      default: return Icons.star;
    }
  }

  Color _getLevelColor(PlayerStats stats) {
    final colorHex = stats.levelColor;
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }
} 