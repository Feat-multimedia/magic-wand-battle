import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/spell_model.dart';
import '../../services/spell_service.dart';

class SpellManagementScreen extends StatefulWidget {
  const SpellManagementScreen({super.key});

  @override
  State<SpellManagementScreen> createState() => _SpellManagementScreenState();
}

class _SpellManagementScreenState extends State<SpellManagementScreen> {
  List<SpellModel> _spells = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  Set<String> _selectedSpells = {};
  Map<String, dynamic> _spellStats = {};

  @override
  void initState() {
    super.initState();
    _loadSpells();
  }

  Future<void> _loadSpells() async {
    setState(() => _isLoading = true);
    try {
      final spells = await SpellService.getAllSpells();
      final stats = await SpellService.getSpellStats();
      setState(() {
        _spells = spells;
        _spellStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedSpells() async {
    if (_selectedSpells.isEmpty) return;
    
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() => _isDeleting = true);
    try {
      await SpellService.deleteMultipleSpells(_selectedSpells.toList());
      setState(() => _selectedSpells.clear());
      await _loadSpells();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSpells.length} sorts supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${_selectedSpells.length} sort(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _fixChifoumiRelations() async {
    try {
      setState(() => _isLoading = true);
      final remainingSpellIds = _spells.map((s) => s.id).toList();
      await SpellService.fixChifoumiRelations(remainingSpellIds);
      await _loadSpells();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relations chifoumi réparées !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Gestion des Sorts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/spells/create'),
            tooltip: 'Créer un nouveau sort',
          ),
          if (_selectedSpells.isNotEmpty)
            IconButton(
              icon: _isDeleting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _deleteSelectedSpells,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header avec statistiques
                    _buildStatsHeader(),
                    const SizedBox(height: 24),
                    
                    // Actions rapides
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    
                    // Liste des sorts
                    Expanded(
                      child: _spells.isEmpty
                          ? _buildEmptyState()
                          : _buildSpellsList(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Système de Sorts',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_spellStats['total'] ?? 0} sorts au total',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Indicateurs de statut
          Row(
            children: [
              Expanded(
                child: _buildStatusIndicator(
                  'Relations Valides',
                  '${_spellStats['validRelations'] ?? 0}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusIndicator(
                  'Relations Cassées',
                  '${_spellStats['invalidRelations'] ?? 0}',
                  Colors.red,
                  Icons.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusIndicator(
                  'Système',
                  (_spellStats['isSystemValid'] ?? false) ? 'OK' : 'Cassé',
                  (_spellStats['isSystemValid'] ?? false) ? Colors.green : Colors.orange,
                  (_spellStats['isSystemValid'] ?? false) ? Icons.verified : Icons.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loadSpells,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (_spellStats['invalidRelations'] ?? 0) > 0 ? _fixChifoumiRelations : null,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Réparer Relations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_fix_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun sort trouvé',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les sorts apparaîtront ici une fois créés',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        children: [
          // Header de la liste
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedSpells.length == _spells.length && _spells.isNotEmpty,
                  tristate: _selectedSpells.isNotEmpty && _selectedSpells.length < _spells.length,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedSpells = _spells.map((s) => s.id).toSet();
                      } else {
                        _selectedSpells.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Nom du Sort',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedSpells.length} sélectionné(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des sorts
          Expanded(
            child: ListView.builder(
              itemCount: _spells.length,
              itemBuilder: (context, index) {
                final spell = _spells[index];
                final isSelected = _selectedSpells.contains(spell.id);
                final beatenSpell = _spells.firstWhere(
                  (s) => s.id == spell.beats,
                  orElse: () => SpellModel(
                    id: '',
                    name: 'Inconnu',
                    gestureData: GestureData(
                      accelerometerReadings: [],
                      gyroscopeReadings: [],
                      threshold: 0.0,
                      duration: 0,
                    ),
                    voiceKeyword: '',
                    beats: '',
                    createdAt: DateTime.now(),
                  ),
                );
                
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.05) : null,
                    border: index < _spells.length - 1 
                        ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
                        : null,
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedSpells.add(spell.id);
                          } else {
                            _selectedSpells.remove(spell.id);
                          }
                        });
                      },
                    ),
                    title: Text(
                      spell.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF3B82F6) : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mot magique: "${spell.voiceKeyword}"'),
                        Text('Bat: ${beatenSpell.name}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          spell.beats.isNotEmpty ? Icons.link : Icons.link_off,
                          color: spell.beats.isNotEmpty ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => context.push('/admin/spells/edit/${spell.id}'),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Supprimer "${spell.name}"'),
                                content: const Text('Cette action est irréversible.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              try {
                                await SpellService.deleteSpell(spell.id);
                                await _loadSpells();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Sort "${spell.name}" supprimé'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 