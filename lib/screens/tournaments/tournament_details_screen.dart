import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common_widgets.dart';

class TournamentDetailsScreen extends StatefulWidget {
  final String tournamentId;
  
  const TournamentDetailsScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailsScreen> createState() => _TournamentDetailsScreenState();
}

class _TournamentDetailsScreenState extends State<TournamentDetailsScreen> with TickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService();
  
  TournamentModel? _tournament;
  List<UserModel> _participants = [];
  bool _isLoading = true;
  bool _isRegistered = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTournamentDetails();
  }

  Future<void> _loadTournamentDetails() async {
    setState(() => _isLoading = true);
    
    try {
      final tournament = await _tournamentService.getTournamentById(widget.tournamentId);
      if (tournament != null) {
        setState(() {
          _tournament = tournament;
          _isRegistered = tournament.registeredPlayerIds.contains(AuthService.currentUser?.uid);
        });
        
        // Charger les participants
        await _loadParticipants();
      }
    } catch (e) {
      Logger.error('Erreur chargement détails tournoi', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadParticipants() async {
    if (_tournament == null) return;
    
    try {
      final participants = <UserModel>[];
      for (final playerId in _tournament!.registeredPlayerIds) {
        // Simuler les participants pour l'instant
        final user = UserModel(
          id: playerId,
          email: 'player${playerId.substring(0, 8)}@example.com',
          displayName: 'Joueur ${playerId.substring(0, 8)}',
          isAdmin: false,
          stats: UserStats(
            matchsPlayed: 10,
            spellsUsed: {'fireball': 5, 'lightning': 3, 'healing': 2},
            totalPoints: 25.5,
            successRate: 0.7,
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        );
        participants.add(user);
      }
      
      setState(() => _participants = participants);
    } catch (e) {
      Logger.error('Erreur chargement participants', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tournament == null
              ? _buildErrorState()
              : _buildContent(),
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
              'Tournoi introuvable',
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

  Widget _buildContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(),
      ],
      body: Column(
        children: [
          // En-tête avec informations principales
          _buildHeaderCard(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: Colors.purple.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple.shade600,
            tabs: const [
              Tab(icon: Icon(Icons.info), text: 'Infos'),
              Tab(icon: Icon(Icons.people), text: 'Participants'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Récompenses'),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildParticipantsTab(),
                _buildRewardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final tournament = _tournament!;
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.purple.shade600,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          tournament.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade400,
                Colors.purple.shade800,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Motif de fond
              Positioned(
                right: -50,
                top: -50,
                child: Icon(
                  Icons.emoji_events,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              
              // Statut du tournoi
              Positioned(
                top: 60,
                right: 16,
                child: _buildStatusBadge(tournament.status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case TournamentStatus.draft:
        color = Colors.grey;
        label = 'Brouillon';
        icon = Icons.edit;
        break;
      case TournamentStatus.registration:
        color = Colors.blue;
        label = 'Inscriptions ouvertes';
        icon = Icons.how_to_reg;
        break;
      case TournamentStatus.ready:
        color = Colors.green;
        label = 'Prêt à commencer';
        icon = Icons.check_circle;
        break;
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
      case TournamentStatus.cancelled:
        color = Colors.red;
        label = 'Annulé';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final tournament = _tournament!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (_tournament!.description.isNotEmpty) ...[
            Text(
              _tournament!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Statistiques principales
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  label: 'Participants',
                  value: '${tournament.registeredPlayerIds.length}/${tournament.maxParticipants}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  label: 'Créé le',
                  value: _formatDate(tournament.createdAt),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Dates importantes
          if (tournament.startDate != null || tournament.registrationDeadline != null)
            Row(
              children: [
                if (tournament.registrationDeadline != null)
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.schedule,
                      label: 'Inscription limite',
                      value: _formatDate(tournament.registrationDeadline!),
                      color: Colors.orange,
                    ),
                  ),
                if (tournament.startDate != null) ...[
                  if (tournament.registrationDeadline != null) const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.play_arrow,
                      label: 'Début prévu',
                      value: _formatDate(tournament.startDate!),
                      color: Colors.purple,
                    ),
                  ),
                ],
              ],
            ),
          
          const SizedBox(height: 20),
          
          // Bouton d'action principal
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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

  Widget _buildActionButton() {
    final tournament = _tournament!;
    
    switch (tournament.status) {
      case TournamentStatus.registration:
        if (_isRegistered) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _unregisterFromTournament,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Se désinscrire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tournament.registeredPlayerIds.length < tournament.maxParticipants
                  ? _registerForTournament
                  : null,
              icon: const Icon(Icons.how_to_reg),
              label: Text(tournament.registeredPlayerIds.length < tournament.maxParticipants
                  ? 'S\'inscrire'
                  : 'Complet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          );
        }
        
      case TournamentStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/tournaments/${tournament.id}/bracket',
            ),
            icon: const Icon(Icons.account_tree),
            label: const Text('Voir le bracket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
        
      case TournamentStatus.finished:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/tournaments/${tournament.id}/results',
            ),
            icon: const Icon(Icons.emoji_events),
            label: const Text('Voir les résultats'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoTab() {
    final tournament = _tournament!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: 'Format du tournoi',
            icon: Icons.category,
            children: [
              _buildInfoRow('Type', _getTypeLabel(tournament.type)),
              _buildInfoRow('Participants min', '${tournament.minParticipants}'),
              _buildInfoRow('Participants max', '${tournament.maxParticipants}'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection(
            title: 'Règles et configuration',
            icon: Icons.rule,
            children: [
              if (tournament.allowedSpellIds?.isNotEmpty == true)
                _buildInfoRow('Sorts autorisés', '${tournament.allowedSpellIds!.length} sorts'),
              if (tournament.arenaId?.isNotEmpty == true)
                _buildInfoRow('Arène', tournament.arenaId!),
              _buildInfoRow('Créé par', 'Organisateur'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection(
            title: 'Progression',
            icon: Icons.trending_up,
            children: [
              _buildProgressBar(
                'Inscriptions',
                tournament.registeredPlayerIds.length.toDouble(),
                tournament.maxParticipants.toDouble(),
                Colors.blue,
              ),
              if (tournament.canStart)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Le tournoi peut commencer',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.people, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Participants inscrits (${_participants.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste des participants
          if (_participants.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun participant inscrit',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return _buildParticipantCard(participant, index + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(UserModel participant, int position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple.shade100,
            child: Text(
              '#$position',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            participant.displayName ?? 'Joueur ${participant.id.substring(0, 8)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'Inscrit le ${_formatDate(DateTime.now())}', // TODO: Date réelle d'inscription
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${participant.stats.matchsPlayed}M',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '${participant.stats.totalPoints.toStringAsFixed(1)}pts',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    final tournament = _tournament!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text(
                'Récompenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Récompenses configurées
          if (tournament.rewards.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tournament.rewards.length,
              itemBuilder: (context, index) {
                final reward = tournament.rewards[index];
                return _buildRewardCard(reward, index + 1);
              },
            ),
          ] else ...[
            // Récompenses par défaut
            _buildDefaultRewardCard(1, 'Champion', Colors.amber, Icons.emoji_events),
            _buildDefaultRewardCard(2, 'Vice-Champion', Colors.grey, Icons.workspace_premium),
            _buildDefaultRewardCard(3, 'Troisième place', Colors.orange, Icons.workspace_premium),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les récompenses seront distribuées automatiquement à la fin du tournoi.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
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

  Widget _buildRewardCard(TournamentReward reward, int position) {
    Color color;
    IconData icon;
    
    switch (position) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey;
        icon = Icons.workspace_premium;
        break;
      case 3:
        color = Colors.orange;
        icon = Icons.workspace_premium;
        break;
      default:
        color = Colors.blue;
        icon = Icons.star;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reward.description.isNotEmpty)
                      Text(
                        reward.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              
              Text(
                '#$position',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultRewardCard(int position, String title, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: const Text('Récompense par défaut'),
          trailing: Text(
            '#$position',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double current, double max, Color color) {
    final percentage = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            Text(
              '${current.toInt()}/${max.toInt()}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  // Actions
  Future<void> _registerForTournament() async {
    if (AuthService.currentUser == null) return;
    
    final success = await _tournamentService.registerPlayer(
      widget.tournamentId,
      AuthService.currentUser!.uid,
    );
    
    if (mounted) {
      if (success) {
        SoundNotification.show(context, message: '✅ Inscription réussie !');
        await _loadTournamentDetails();
      } else {
        SoundNotification.show(context, message: '❌ Erreur lors de l\'inscription');
      }
    }
  }

  Future<void> _unregisterFromTournament() async {
    if (AuthService.currentUser == null) return;
    
    final success = await _tournamentService.unregisterPlayer(
      widget.tournamentId,
      AuthService.currentUser!.uid,
    );
    
    if (mounted) {
      if (success) {
        SoundNotification.show(context, message: '✅ Désinscription effectuée');
        await _loadTournamentDetails();
      } else {
        SoundNotification.show(context, message: '❌ Erreur lors de la désinscription');
      }
    }
  }

  // Utilitaires
  String _getTypeLabel(TournamentType type) {
    switch (type) {
      case TournamentType.singleElimination:
        return 'Élimination directe';
      case TournamentType.doubleElimination:
        return 'Double élimination';
      case TournamentType.roundRobin:
        return 'Round Robin (Tous contre tous)';
      case TournamentType.swiss:
        return 'Système suisse';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 