import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/tournament_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common_widgets.dart';

class EditTournamentScreen extends StatefulWidget {
  final String tournamentId;
  
  const EditTournamentScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<EditTournamentScreen> createState() => _EditTournamentScreenState();
}

class _EditTournamentScreenState extends State<EditTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TournamentService _tournamentService = TournamentService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _minParticipantsController = TextEditingController();
  
  // Form data
  TournamentModel? _originalTournament;
  TournamentType _selectedType = TournamentType.singleElimination;
  DateTime? _startDate;
  DateTime? _registrationDeadline;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  Future<void> _loadTournament() async {
    setState(() => _isLoading = true);
    
    try {
      final tournament = await _tournamentService.getTournamentById(widget.tournamentId);
      if (tournament != null) {
        setState(() {
          _originalTournament = tournament;
          _populateForm(tournament);
        });
      }
    } catch (e) {
      Logger.error('Erreur chargement tournoi pour édition', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateForm(TournamentModel tournament) {
    _nameController.text = tournament.name;
    _descriptionController.text = tournament.description;
    _maxParticipantsController.text = tournament.maxParticipants.toString();
    _minParticipantsController.text = tournament.minParticipants.toString();
    
    _selectedType = tournament.type;
    _startDate = tournament.startDate;
    _registrationDeadline = tournament.registrationDeadline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ Modifier le Tournoi'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _originalTournament != null)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveTournament,
              icon: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Sauvegarde...' : 'Sauvegarder',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _originalTournament == null
              ? _buildErrorState()
              : _buildEditForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avertissement si tournoi déjà commencé
          if (_originalTournament!.status != TournamentStatus.draft &&
              _originalTournament!.status != TournamentStatus.registration)
            _buildWarningCard(),
          
          // Informations de base
          _buildBasicInfoSection(),
          
          const SizedBox(height: 24),
          
          // Configuration du tournoi
          _buildConfigurationSection(),
          
          const SizedBox(height: 24),
          
          // Dates
          _buildDatesSection(),
          
          const SizedBox(height: 24),
          
          // Participants
          _buildParticipantsSection(),
          
          const SizedBox(height: 32),
          
          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tournoi en cours',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                Text(
                  'Certaines modifications peuvent être limitées car le tournoi a déjà commencé.',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Informations de base',
      icon: Icons.info,
      children: [
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
          enabled: _canEditBasicInfo(),
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return _buildSection(
      title: 'Configuration',
      icon: Icons.settings,
      children: [
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
          onChanged: _canEditBasicInfo() ? (value) {
            setState(() => _selectedType = value!);
          } : null,
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return _buildSection(
      title: 'Planification',
      icon: Icons.schedule,
      children: [
        // Date limite d'inscription
        InkWell(
          onTap: _canEditDates() ? () => _selectRegistrationDeadline() : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date limite d\'inscription',
              prefixIcon: const Icon(Icons.schedule),
              border: const OutlineInputBorder(),
              enabled: _canEditDates(),
            ),
            child: Text(
              _registrationDeadline != null
                  ? _formatDate(_registrationDeadline!)
                  : 'Non définie',
              style: TextStyle(
                color: _canEditDates() ? null : Colors.grey,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Date de début
        InkWell(
          onTap: _canEditDates() ? () => _selectStartDate() : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date de début prévue',
              prefixIcon: const Icon(Icons.play_arrow),
              border: const OutlineInputBorder(),
              enabled: _canEditDates(),
            ),
            child: Text(
              _startDate != null
                  ? _formatDate(_startDate!)
                  : 'Non définie',
              style: TextStyle(
                color: _canEditDates() ? null : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return _buildSection(
      title: 'Participants',
      icon: Icons.people,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Minimum',
                  prefixIcon: Icon(Icons.person_remove),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 2) {
                    return 'Min. 2';
                  }
                  return null;
                },
                enabled: _canEditParticipants(),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum',
                  prefixIcon: Icon(Icons.person_add),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  final minNumber = int.tryParse(_minParticipantsController.text) ?? 2;
                  
                  if (number == null || number < minNumber) {
                    return 'Doit être ≥ min';
                  }
                  if (number > 64) {
                    return 'Max. 64';
                  }
                  
                  // Vérifier qu'on ne réduit pas en dessous du nombre actuel d'inscrits
                  if (_originalTournament != null && 
                      number < _originalTournament!.registeredPlayerIds.length) {
                    return 'Impossible: ${_originalTournament!.registeredPlayerIds.length} déjà inscrits';
                  }
                  
                  return null;
                },
                enabled: _canEditParticipants(),
              ),
            ),
          ],
        ),
        
        // Affichage des inscrits actuels
        if (_originalTournament!.registeredPlayerIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Actuellement ${_originalTournament!.registeredPlayerIds.length} participants inscrits',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Sauvegarder
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveTournament,
            icon: _isSaving 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
            label: Text(_isSaving ? 'Sauvegarde en cours...' : 'Sauvegarder les modifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Annuler
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
            label: const Text('Annuler'),
          ),
        ),
      ],
    );
  }

  // Sélecteurs de date
  Future<void> _selectRegistrationDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _registrationDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _registrationDeadline = date);
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _registrationDeadline ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  // Permissions d'édition
  bool _canEditBasicInfo() {
    if (_originalTournament == null) return true;
    return _originalTournament!.status == TournamentStatus.draft ||
           _originalTournament!.status == TournamentStatus.registration;
  }

  bool _canEditDates() {
    if (_originalTournament == null) return true;
    return _originalTournament!.status == TournamentStatus.draft ||
           _originalTournament!.status == TournamentStatus.registration;
  }

  bool _canEditParticipants() {
    if (_originalTournament == null) return true;
    return _originalTournament!.status == TournamentStatus.draft ||
           _originalTournament!.status == TournamentStatus.registration;
  }

  // Sauvegarde
  Future<void> _saveTournament() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final updatedTournament = _originalTournament!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        maxParticipants: int.parse(_maxParticipantsController.text),
        minParticipants: int.parse(_minParticipantsController.text),
        startDate: _startDate,
        registrationDeadline: _registrationDeadline,
      );
      
      final result = await _tournamentService.updateTournament(
        widget.tournamentId,
        updatedTournament,
      );
      
      if (result != null && mounted) {
        SoundNotification.show(context, message: '✅ Tournoi modifié avec succès !');
        Navigator.pop(context, true); // Retourner true pour indiquer une modification
      } else if (mounted) {
        SoundNotification.show(context, message: '❌ Erreur lors de la modification');
      }
    } catch (e) {
      Logger.error('Erreur modification tournoi', error: e);
      if (mounted) {
        SoundNotification.show(context, message: '❌ Erreur lors de la modification');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Utilitaires
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _minParticipantsController.dispose();
    super.dispose();
  }
} 