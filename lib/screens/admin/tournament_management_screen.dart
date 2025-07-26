import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common_widgets.dart';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  State<TournamentManagementScreen> createState() => _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen> {
  final TournamentService _tournamentService = TournamentService();
  List<TournamentModel> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() => _isLoading = true);
    try {
      final tournaments = await _tournamentService.getAllTournaments();
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Erreur chargement tournois', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Gestion des Tournois'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournaments,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Header Tournois
                      _buildTournamentHeader(),
                      const SizedBox(height: 40),
                      
                      // Bouton créer tournoi
                      _buildCreateTournamentButton(),
                      const SizedBox(height: 32),
                      
                      // Liste des tournois
                      _buildTournamentsList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTournamentHeader() {
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
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Tournoi avec effet
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF7C3AED),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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
            'Gestion des Tournois',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Organisez et gérez les compétitions épiques',
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

  Widget _buildCreateTournamentButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showCreateTournamentDialog(),
        icon: const Icon(Icons.add_circle, color: Colors.white),
        label: const Text(
          'Créer un Nouveau Tournoi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentsList() {
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
                child: const Icon(Icons.list, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Tournois Existants (${_tournaments.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_tournaments.isEmpty) 
            _buildEmptyTournamentsState()
          else
                      ..._tournaments.map((tournament) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildModernTournamentCard(tournament),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyTournamentsState() {
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
            'Aucun tournoi créé',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre premier tournoi avec le bouton ci-dessus',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTournamentCard(TournamentModel tournament) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: _buildTournamentCard(tournament),
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    final statusColor = _getStatusColor(tournament.status);
    final statusIcon = _getStatusIcon(tournament.status);
    final typeLabel = _getTypeLabel(tournament.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SoundCard(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusLabel(tournament.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            if (tournament.description.isNotEmpty)
              Text(
                tournament.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Infos du tournoi
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.category,
                  label: typeLabel,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.people,
                  label: '${tournament.registeredPlayerIds.length}/${tournament.maxParticipants}',
                  color: Colors.green,
                ),
                if (tournament.startDate != null) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.schedule,
                    label: _formatDate(tournament.startDate!),
                    color: Colors.orange,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Barre de progression des inscriptions
            if (tournament.status == TournamentStatus.registration)
              Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.how_to_reg,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Inscriptions: ${tournament.registeredPlayerIds.length}/${tournament.maxParticipants}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: tournament.registrationProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      tournament.canStart ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                // Voir détails
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewTournamentDetails(tournament),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Action principale selon le statut
                Expanded(
                  child: _buildPrimaryActionButton(tournament),
                ),

                const SizedBox(width: 8),

                // Menu actions
                PopupMenuButton<String>(
                  onSelected: (action) => _handleTournamentAction(tournament, action),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (tournament.status == TournamentStatus.draft)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(TournamentModel tournament) {
    switch (tournament.status) {
      case TournamentStatus.draft:
        return ElevatedButton.icon(
          onPressed: () => _openRegistrations(tournament),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Ouvrir'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
          ),
        );

      case TournamentStatus.registration:
        return ElevatedButton.icon(
          onPressed: tournament.canStart ? () => _startTournament(tournament) : null,
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Démarrer'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: tournament.canStart ? Colors.purple : Colors.grey,
          ),
        );

      case TournamentStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: () => _viewBracket(tournament),
          icon: const Icon(Icons.account_tree, size: 18),
          label: const Text('Bracket'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
          ),
        );

      case TournamentStatus.finished:
        return ElevatedButton.icon(
          onPressed: () => _viewResults(tournament),
          icon: const Icon(Icons.emoji_events, size: 18),
          label: const Text('Résultats'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.amber,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // Méthodes utilitaires pour les statuts
  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return Colors.grey;
      case TournamentStatus.registration:
        return Colors.blue;
      case TournamentStatus.ready:
        return Colors.green;
      case TournamentStatus.inProgress:
        return Colors.orange;
      case TournamentStatus.finished:
        return Colors.purple;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return Icons.edit;
      case TournamentStatus.registration:
        return Icons.how_to_reg;
      case TournamentStatus.ready:
        return Icons.check_circle;
      case TournamentStatus.inProgress:
        return Icons.play_circle;
      case TournamentStatus.finished:
        return Icons.emoji_events;
      case TournamentStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return 'Brouillon';
      case TournamentStatus.registration:
        return 'Inscriptions';
      case TournamentStatus.ready:
        return 'Prêt';
      case TournamentStatus.inProgress:
        return 'En cours';
      case TournamentStatus.finished:
        return 'Terminé';
      case TournamentStatus.cancelled:
        return 'Annulé';
    }
  }

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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  // Actions
  void _showCreateTournamentDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateTournamentScreen(),
      ),
    ).then((_) => _loadTournaments());
  }

  void _viewTournamentDetails(TournamentModel tournament) {
    Logger.info('Voir détails tournoi: ${tournament.name}');
    Navigator.pushNamed(
      context, 
      '/tournaments/${tournament.id}/details',
    );
  }

  void _openRegistrations(TournamentModel tournament) async {
    final updated = tournament.copyWith(status: TournamentStatus.registration);
    final result = await _tournamentService.updateTournament(tournament.id, updated);
    if (result != null) {
      _loadTournaments();
      SoundNotification.show(context, message: '✅ Inscriptions ouvertes !');
    }
  }

  void _startTournament(TournamentModel tournament) async {
    final success = await _tournamentService.startTournament(tournament.id);
    if (success) {
      _loadTournaments();
      SoundNotification.show(context, message: '🚀 Tournoi démarré !');
    }
  }

  void _viewBracket(TournamentModel tournament) {
    Logger.info('Voir bracket: ${tournament.name}');
    Navigator.pushNamed(
      context, 
      '/tournaments/${tournament.id}/bracket',
    );
  }

  void _viewResults(TournamentModel tournament) {
    Logger.info('Voir résultats: ${tournament.name}');
    Navigator.pushNamed(
      context, 
      '/tournaments/${tournament.id}/results',
    );
  }

  void _viewLiveTournament(TournamentModel tournament) {
    Logger.info('Suivi live tournoi: ${tournament.name}');
    Navigator.pushNamed(
      context, 
      '/tournaments/${tournament.id}/live',
    );
  }

  void _handleTournamentAction(TournamentModel tournament, String action) {
    switch (action) {
      case 'edit':
        Logger.info('Modifier tournoi: ${tournament.name}');
        Navigator.pushNamed(
          context,
          '/admin/tournaments/${tournament.id}/edit',
        ).then((_) => _loadTournaments());
        break;
      case 'delete':
        _showDeleteConfirmation(tournament);
        break;
    }
  }

  void _showDeleteConfirmation(TournamentModel tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le tournoi'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${tournament.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _tournamentService.deleteTournament(tournament.id);
              if (success) {
                _loadTournaments();
                SoundNotification.show(context, message: '🗑️ Tournoi supprimé');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Écran de création de tournoi (simplifié pour l'instant)
class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TournamentService _tournamentService = TournamentService();

  TournamentType _selectedType = TournamentType.singleElimination;
  int _maxParticipants = 8;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🆕 Nouveau Tournoi'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nom du tournoi
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du tournoi',
                prefixIcon: Icon(Icons.emoji_events),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Type de tournoi
            DropdownButtonFormField<TournamentType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de tournoi',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: TournamentType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeDescription(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),

            const SizedBox(height: 16),

            // Nombre maximum de participants
            TextFormField(
              initialValue: _maxParticipants.toString(),
              decoration: const InputDecoration(
                labelText: 'Nombre max de participants',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final number = int.tryParse(value ?? '');
                if (number == null || number < 2) {
                  return 'Minimum 2 participants';
                }
                if (number > 64) {
                  return 'Maximum 64 participants';
                }
                return null;
              },
              onChanged: (value) {
                final number = int.tryParse(value);
                if (number != null) {
                  _maxParticipants = number;
                }
              },
            ),

            const SizedBox(height: 24),

            // Bouton créer
            ElevatedButton(
              onPressed: _isCreating ? null : _createTournament,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Créer le tournoi', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDescription(TournamentType type) {
    switch (type) {
      case TournamentType.singleElimination:
        return 'Élimination directe - Rapide et classique';
      case TournamentType.doubleElimination:
        return 'Double élimination - Seconde chance';
      case TournamentType.roundRobin:
        return 'Round Robin - Tous contre tous';
      case TournamentType.swiss:
        return 'Système suisse - Appariements intelligents';
    }
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      await _tournamentService.createTournament(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        maxParticipants: _maxParticipants,
      );

      if (mounted) {
        Navigator.pop(context);
        SoundNotification.show(context, message: '🎉 Tournoi créé avec succès !');
      }
    } catch (e) {
      Logger.error('Erreur création tournoi', error: e);
      if (mounted) {
        SoundNotification.show(context, message: '❌ Erreur lors de la création');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 