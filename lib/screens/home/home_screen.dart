import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/arena_service.dart';
import '../../models/match_model.dart';

import '../../utils/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MatchModel> _playerMatches = [];
  bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerMatches();
  }

  Future<void> _loadPlayerMatches() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userProfile?.id;
    
    if (userId == null) return;

    setState(() => _isLoadingMatches = true);

    try {
      final matches = await ArenaService.getActiveMatchesForPlayer(userId);
      setState(() {
        _playerMatches = matches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      Logger.error(' Erreur chargement matchs: $e');
      setState(() => _isLoadingMatches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userName = authProvider.userProfile?.displayName ?? 'Sorcier';
        final isAdmin = authProvider.isAdmin;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            title: const Text('Magic Wand Battle'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.push(AppConstants.profileRoute),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _handleLogout(context),
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
                    // Header élégant et centré
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
                          // Avatar avec effet
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.tertiary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_fix_high,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Nom et titre
                          Text(
                            'Bienvenue, $userName !',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAdmin
                              ? 'Administrez les duels magiques'
                              : 'Prêt pour un combat épique ?',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Status badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                                    : const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isAdmin
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                                      size: 18,
                                      color: isAdmin
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAdmin ? 'Game Master' : 'Joueur',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isAdmin
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Color(0xFF10B981),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'En ligne',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Section des matchs actifs (pour les joueurs non-admin)
                    if (!isAdmin) _buildActiveMatchesSection(),

                    const SizedBox(height: 48),

                    // Menu des actions
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth > 600) crossAxisCount = 3;
                        if (constraints.maxWidth > 900) crossAxisCount = 4;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.0,
                          children: [
                            _buildMenuCard(
                              context,
                              icon: Icons.refresh,
                              title: 'Actualiser Duels',
                              subtitle: 'Rechercher nouveaux matchs',
                              color: const Color(0xFF3B82F6),
                              onTap: () => _loadPlayerMatches(),
                            ),
                            _buildMenuCard(
                              context,
                              icon: Icons.fitness_center,
                              title: 'Entraînement',
                              subtitle: 'Perfectionner vos sorts',
                              color: const Color(0xFF10B981),
                              onTap: () => context.push('/duel/training/solo'),
                            ),
                            _buildMenuCard(
                              context,
                              icon: Icons.emoji_events,
                              title: '🏆 Tournois',
                              subtitle: 'Rejoindre des compétitions',
                              color: const Color(0xFF9333EA),
                              onTap: () => context.push('/tournaments'),
                            ),
                            _buildMenuCard(
                              context,
                              icon: Icons.bar_chart,
                              title: 'Statistiques',
                              subtitle: 'Vos performances',
                              color: const Color(0xFF8B5CF6),
                              onTap: () => context.push(AppConstants.profileRoute),
                            ),
                            _buildMenuCard(
                              context,
                              icon: Icons.leaderboard,
                              title: 'Classement',
                              subtitle: 'Meilleurs joueurs',
                              color: const Color(0xFFF59E0B),
                              onTap: () => context.push('/leaderboard'),
                            ),
                            if (isAdmin)
                              _buildMenuCard(
                                context,
                                icon: Icons.admin_panel_settings,
                                title: 'Administration',
                                subtitle: 'Contrôler les matchs',
                                color: const Color(0xFFF59E0B),
                                onTap: () => context.push(AppConstants.adminRoute),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    // Footer info
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Version Beta',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Application en cours de développement avec fonctionnalités limitées',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMatchesSection() {
    return Container(
      padding: const EdgeInsets.all(32.0),
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_kabaddi,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚔️ Vos Duels',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Matchs en attente et en cours',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingMatches)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadPlayerMatches,
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_isLoadingMatches)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_playerMatches.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
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
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun duel en cours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Patientez qu\'un Game Master vous assigne un match',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: _playerMatches.map((match) => _buildMatchCard(match)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              // Statut du match
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getMatchStatusColor(match.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getMatchStatusText(match.status),
                  style: TextStyle(
                    color: _getMatchStatusColor(match.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Best of ${match.roundsToWin}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Informations du match
          FutureBuilder<String>(
            future: _getOpponentName(match),
            builder: (context, snapshot) {
              final opponentName = snapshot.data ?? 'Chargement...';
              
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adversaire',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opponentName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _joinMatch(match),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Rejoindre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<String> _getOpponentName(MatchModel match) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userProfile?.id;
      
      // Déterminer l'adversaire
      final opponentRef = match.player1.id == currentUserId 
          ? match.player2 
          : match.player1;
      
      return await ArenaService.getUserNameFromRef(opponentRef);
    } catch (e) {
      return 'Erreur';
    }
  }

  Color _getMatchStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.pending:
        return const Color(0xFFF59E0B);
      case MatchStatus.inProgress:
        return const Color(0xFF10B981);
      case MatchStatus.finished:
        return const Color(0xFF6B7280);
    }
  }

  String _getMatchStatusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.pending:
        return 'En attente';
      case MatchStatus.inProgress:
        return 'En cours';
      case MatchStatus.finished:
        return 'Terminé';
    }
  }

  void _joinMatch(MatchModel match) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.id;
    
    if (currentUserId == null) return;

    // Naviguer vers l'écran de duel avec les boons paramètres
    context.push('/duel/${match.id}/$currentUserId');
  }



  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (context.mounted) {
      context.go(AppConstants.loginRoute);
    }
  }
} 