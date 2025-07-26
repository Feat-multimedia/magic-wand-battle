import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/arena_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/logger.dart';

class ArenaManagementScreen extends StatefulWidget {
  const ArenaManagementScreen({super.key});

  @override
  State<ArenaManagementScreen> createState() => _ArenaManagementScreenState();
}

class _ArenaManagementScreenState extends State<ArenaManagementScreen> {
  final _titleController = TextEditingController();
  final _maxRoundsController = TextEditingController(text: '3');
  
  ArenaType _selectedType = ArenaType.exhibition;
  List<UserModel> _availableUsers = [];
  List<String> _selectedPlayerIds = [];
  List<ArenaModel> _arenas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _maxRoundsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadUsers(),
        _loadArenas(),
      ]);
    } catch (e) {
      Logger.debug('Erreur lors du chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'player')
        .get();

    setState(() {
      _availableUsers = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> _loadArenas() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('arenas')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _arenas = snapshot.docs
          .map((doc) => ArenaModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> _createArena() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un titre'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedPlayerIds.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez exactement 2 joueurs'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final currentUser = FirebaseService.auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final playerRefs = _selectedPlayerIds
          .map((id) => FirebaseFirestore.instance.collection('users').doc(id))
          .toList();

      final arena = ArenaModel(
        id: '', // Sera généré par Firestore
        title: _titleController.text.trim(),
        type: _selectedType,
        status: ArenaStatus.waiting,
        createdBy: FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        maxRounds: int.tryParse(_maxRoundsController.text) ?? 3,
        players: playerRefs,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('arenas')
          .add(arena.toFirestore());

      // Réinitialiser le formulaire
      _titleController.clear();
      _selectedPlayerIds.clear();
      _maxRoundsController.text = '3';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arène créée avec succès !'), backgroundColor: Colors.green),
      );

      await _loadArenas();
    } catch (e) {
      Logger.debug('Erreur création arène: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startMatch(ArenaModel arena) async {
    if (!arena.canStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer ce match'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // Créer le match
      final match = MatchModel(
        id: '', // Sera généré par Firestore
        arenaId: FirebaseFirestore.instance.collection('arenas').doc(arena.id),
        player1: arena.players[0],
        player2: arena.players[1],
        status: MatchStatus.inProgress,
        roundsToWin: arena.maxRounds,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('matches')
          .add(match.toFirestore());

      // Mettre à jour le statut de l'arène
      await FirebaseFirestore.instance
          .collection('arenas')
          .doc(arena.id)
          .update({'status': 'inProgress'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match démarré !'), backgroundColor: Colors.green),
      );

      await _loadArenas();
    } catch (e) {
      Logger.debug('Erreur démarrage match: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Gestion des Arènes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        // Header Gestion Arènes
                        _buildArenaHeader(),
                        const SizedBox(height: 40),
                        
                        // Formulaire de création
                        _buildCreateArenaForm(),
                        const SizedBox(height: 32),
                        
                        // Liste des arènes existantes
                        _buildArenasListSection(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildArenaHeader() {
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
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Arène avec effet
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_kabaddi,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Titre
          Text(
            'Gestion des Arènes',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Créez et gérez les arènes de combat magique',
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

  Widget _buildArenasListSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                'Arènes Existantes (${_arenas.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_arenas.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Aucune arène créée pour le moment',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...(_arenas.map((arena) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildArenaCard(arena),
            ))),
        ],
      ),
    );
  }

  Widget _buildCreateArenaForm() {
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
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
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
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_circle, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Créer une Nouvelle Arène',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Titre
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre de l\'arène',
              hintText: 'Ex: Duel des Champions',
              border: OutlineInputBorder(),
            ),
          ),
            const SizedBox(height: 16),
            
            // Type d'arène
            DropdownButtonFormField<ArenaType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type d\'arène',
                border: OutlineInputBorder(),
              ),
              items: ArenaType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == ArenaType.exhibition ? '🎪 Exhibition' : '🏆 Tournoi'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Nombre de rounds
            TextField(
              controller: _maxRoundsController,
              decoration: const InputDecoration(
                labelText: 'Rounds pour gagner',
                hintText: '3',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Sélection des joueurs
            Text(
              'Joueurs (${_selectedPlayerIds.length}/2)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _availableUsers.length,
                itemBuilder: (context, index) {
                  final user = _availableUsers[index];
                  final isSelected = _selectedPlayerIds.contains(user.id);
                  
                  return CheckboxListTile(
                    title: Text(user.displayName),
                    subtitle: Text(user.email),
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true && _selectedPlayerIds.length < 2) {
                          _selectedPlayerIds.add(user.id);
                        } else if (selected == false) {
                          _selectedPlayerIds.remove(user.id);
                        }
                      });
                    },
                    enabled: _selectedPlayerIds.length < 2 || isSelected,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Bouton créer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createArena,
                icon: const Icon(Icons.add),
                label: const Text('Créer l\'Arène'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildArenaCard(ArenaModel arena) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  arena.type == ArenaType.exhibition ? Icons.theater_comedy : Icons.emoji_events,
                  color: _getStatusColor(arena.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    arena.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _buildStatusChip(arena.status),
              ],
            ),
            const SizedBox(height: 8),
            
            Text('Rounds pour gagner: ${arena.maxRounds}'),
            Text('Joueurs: ${arena.players.length}/2'),
            Text('Créé le: ${_formatDate(arena.createdAt)}'),
            
            if (arena.canStart) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startMatch(arena),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer le Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ArenaStatus status) {
    final config = _getStatusConfig(status);
    return Chip(
      label: Text(
        config['label']!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: config['color']! as Color,
    );
  }

  Map<String, dynamic> _getStatusConfig(ArenaStatus status) {
    switch (status) {
      case ArenaStatus.waiting:
        return {'label': 'En attente', 'color': Colors.orange};
      case ArenaStatus.inProgress:
        return {'label': 'En cours', 'color': Colors.blue};
      case ArenaStatus.finished:
        return {'label': 'Terminé', 'color': Colors.grey};
    }
  }

  Color _getStatusColor(ArenaStatus status) {
    return _getStatusConfig(status)['color']! as Color;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 