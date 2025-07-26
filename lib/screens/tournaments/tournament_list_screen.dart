import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common_widgets.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
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
      // Filtrer pour montrer seulement les tournois avec inscriptions ouvertes ou en cours
      final availableTournaments = tournaments.where((t) => 
        t.status == TournamentStatus.registration || 
        t.status == TournamentStatus.inProgress ||
        t.status == TournamentStatus.finished
      ).toList();
      
      setState(() {
        _tournaments = availableTournaments;
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
      appBar: AppBar(
        title: const Text('🏆 Tournois'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournaments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTournamentsList(),
    );
  }

  Widget _buildTournamentsList() {
    if (_tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun tournoi disponible',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revenez plus tard pour voir les nouveaux tournois !',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tournaments.length,
      itemBuilder: (context, index) {
        final tournament = _tournaments[index];
        return _buildTournamentCard(tournament);
      },
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    final currentUserId = AuthService.currentUser?.uid;
    final isRegistered = currentUserId != null && 
                        tournament.registeredPlayerIds.contains(currentUserId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(tournament.status),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              if (tournament.description.isNotEmpty)
                Text(
                  tournament.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                  ),
                ),

              const SizedBox(height: 16),

              // Informations du tournoi
              Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.category,
                    label: _getTypeLabel(tournament.type),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 20),
                  _buildInfoItem(
                    icon: Icons.people,
                    label: '${tournament.registeredPlayerIds.length}/${tournament.maxParticipants}',
                    color: Colors.green,
                  ),
                ],
              ),

              if (tournament.startDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoItem(
                      icon: Icons.schedule,
                      label: 'Début: ${_formatDateTime(tournament.startDate!)}',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Barre de progression
              if (tournament.status == TournamentStatus.registration) ...[
                Row(
                  children: [
                    Icon(
                      Icons.how_to_reg,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inscriptions: ${tournament.registeredPlayerIds.length}/${tournament.maxParticipants}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: tournament.registrationProgress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tournament.canStart ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: _buildActionButton(tournament, isRegistered),
              ),

              // Statut d'inscription
              if (isRegistered) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Vous êtes inscrit !',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      case TournamentStatus.registration:
        color = Colors.blue;
        label = 'Inscriptions ouvertes';
        icon = Icons.how_to_reg;
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
      default:
        color = Colors.grey;
        label = 'Non disponible';
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(TournamentModel tournament, bool isRegistered) {
    switch (tournament.status) {
      case TournamentStatus.registration:
        if (isRegistered) {
          return ElevatedButton.icon(
            onPressed: () => _unregisterFromTournament(tournament),
            icon: const Icon(Icons.cancel, size: 20),
            label: const Text('Se désinscrire'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          );
        } else if (tournament.availableSlots > 0) {
          return ElevatedButton.icon(
            onPressed: () => _registerForTournament(tournament),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('S\'inscrire'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          );
        } else {
          return ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.block, size: 20),
            label: const Text('Complet'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          );
        }

      case TournamentStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: () => _viewTournamentBracket(tournament),
          icon: const Icon(Icons.account_tree, size: 20),
          label: const Text('Voir le bracket'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );

      case TournamentStatus.finished:
        return ElevatedButton.icon(
          onPressed: () => _viewTournamentResults(tournament),
          icon: const Icon(Icons.emoji_events, size: 20),
          label: const Text('Voir les résultats'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.purple,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _getTypeLabel(TournamentType type) {
    switch (type) {
      case TournamentType.singleElimination:
        return 'Élimination directe';
      case TournamentType.doubleElimination:
        return 'Double élimination';
      case TournamentType.roundRobin:
        return 'Round Robin';
      case TournamentType.swiss:
        return 'Système suisse';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Actions
  Future<void> _registerForTournament(TournamentModel tournament) async {
    final currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) {
      SoundNotification.show(context, message: '❌ Vous devez être connecté');
      return;
    }

    final success = await _tournamentService.registerPlayer(
      tournament.id, 
      currentUserId,
    );

    if (success) {
      _loadTournaments();
      SoundNotification.show(
        context, 
        message: '🎉 Inscription réussie au tournoi "${tournament.name}" !',
      );
    } else {
      SoundNotification.show(
        context, 
        message: '❌ Erreur lors de l\'inscription',
      );
    }
  }

  Future<void> _unregisterFromTournament(TournamentModel tournament) async {
    final currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) return;

    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la désinscription'),
        content: Text('Voulez-vous vous désinscrire du tournoi "${tournament.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se désinscrire', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _tournamentService.unregisterPlayer(
        tournament.id, 
        currentUserId,
      );

      if (success) {
        _loadTournaments();
        SoundNotification.show(
          context, 
          message: '✅ Désinscription réussie',
        );
      }
    }
  }

  void _viewTournamentBracket(TournamentModel tournament) {
    Logger.info('Voir bracket tournoi: ${tournament.name}');
    Navigator.pushNamed(
      context, 
      '/tournaments/${tournament.id}/bracket',
    );
  }

  void _viewTournamentResults(TournamentModel tournament) {
    Logger.info('Voir résultats tournoi: ${tournament.name}');
    // TODO: Navigation vers écran résultats
    SoundNotification.show(
      context, 
      message: '🚧 Résultats en cours de développement',
    );
  }
} 