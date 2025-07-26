import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/stats_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _stats = {
    'users': 0,
    'spells': 0,
    'arenas': 0,
    'matches': 0,
  };
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await StatsService.getAllStats();
    setState(() {
      _stats = stats;
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Administration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Header Admin
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
                      // Icon Admin avec effet
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
                          Icons.admin_panel_settings,
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
                        'Contrôlez les arènes et orchestrez les duels épiques',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          color: const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Badge Admin
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Administrateur Système',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Actions Admin
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
                        _buildAdminCard(
                          context,
                          icon: Icons.auto_fix_high,
                          title: 'Gérer Sorts',
                          subtitle: 'Configurer la magie',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push('/admin/spells'),
                        ),
                        _buildAdminCard(
                          context,
                          icon: Icons.settings,
                          title: 'Config Firebase',
                          subtitle: 'Setup automatique',
                          color: const Color(0xFFF59E0B),
                          onTap: () => _showNotImplemented(context, 'Configuration Firebase'),
                        ),
                        _buildAdminCard(
                          context,
                          icon: Icons.sports_kabaddi,
                          title: 'Gestion Arènes',
                          subtitle: 'Duels & tournois',
                          color: const Color(0xFF10B981),
                          onTap: () => context.push('/admin/arenas'),
                        ),
                        _buildAdminCard(
                          context,
                          icon: Icons.monitor,
                          title: 'Game Master',
                          subtitle: 'Contrôle live',
                          color: const Color(0xFF3B82F6),
                          onTap: () => context.push('/admin/game-master'),
                        ),
                        _buildAdminCard(
                          context,
                          icon: Icons.emoji_events,
                          title: '🏆 Tournois',
                          subtitle: 'Créer et gérer',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.push('/admin/tournaments'),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Statistiques du système en temps réel
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.people_outline,
                        title: 'Utilisateurs',
                        value: _isLoadingStats ? '...' : '${_stats['users']}',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.auto_fix_high,
                        title: 'Sorts',
                        value: _isLoadingStats ? '...' : '${_stats['spells']}',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.stadium,
                        title: 'Arènes',
                        value: _isLoadingStats ? '...' : '${_stats['arenas']}',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Arènes actives
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                              Row(
                          children: [
                            Icon(
                              Icons.stadium,
                              size: 28,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Arènes Actives',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: _isLoadingStats 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                              onPressed: _isLoadingStats ? null : _loadStats,
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      
                      // Message d'état vide
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune arène active',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Les arènes créées apparaîtront ici',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade500,
                              ),
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
  }

  Widget _buildAdminCard(
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

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotImplemented(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.construction,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(feature),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cette fonctionnalité sera bientôt disponible.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'En cours de développement',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Méthode supprimée car remplacée par _loadStats dans le bouton refresh
} 