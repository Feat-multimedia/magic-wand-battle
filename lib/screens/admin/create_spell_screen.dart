import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/spell_model.dart';
import '../../services/spell_service.dart';

import '../../services/gesture_pattern_service.dart';
import '../../services/audio_service.dart';
import '../../services/sound_service.dart';
import '../../utils/logger.dart';

class CreateSpellScreen extends StatefulWidget {
  final String? spellId; // Si non null, c'est une édition
  
  const CreateSpellScreen({super.key, this.spellId});

  @override
  State<CreateSpellScreen> createState() => _CreateSpellScreenState();
}

class _CreateSpellScreenState extends State<CreateSpellScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _voiceController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  GestureData? _recordedGesture;
  int _recordingProgress = 0;
  String? _selectedSoundId; // 🆕 ID du son sélectionné
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  SpellModel? _existingSpell;

  @override
  void initState() {
    super.initState();
    
    // Animation pour le bouton d'enregistrement
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    if (widget.spellId != null) {
      _loadExistingSpell();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _voiceController.dispose();
    _pulseController.dispose();
    GesturePatternService.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSpell() async {
    setState(() => _isLoading = true);
    try {
      final spell = await SpellService.getSpellById(widget.spellId!);
      if (spell != null) {
        setState(() {
          _existingSpell = spell;
          _nameController.text = spell.name;
          _voiceController.text = spell.voiceKeyword;
          _recordedGesture = spell.gestureData;
          _selectedSoundId = spell.soundFileUrl; // 🆕 Charger l'URL du son
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startRecording() async {
    if (GesturePatternService.isRecording) return;

    setState(() {
      _recordingProgress = 0;
      _recordedGesture = null;
    });
    
    _pulseController.repeat(reverse: true);

    try {
      await GesturePatternService.startRecording(
        onGestureRecorded: (gestureData) {
          setState(() {
            _recordedGesture = gestureData;
            _recordingProgress = 0;
          });
          _pulseController.stop();
          _pulseController.reset();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Mouvement enregistré avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onRecordingProgress: (progress) {
          setState(() {
            _recordingProgress = progress;
          });
        },
        maxDurationMs: 5000,
      );
    } catch (e) {
      _pulseController.stop();
      _pulseController.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _stopRecording() {
    if (GesturePatternService.isRecording) {
      GesturePatternService.stopRecording();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Future<void> _saveSpell() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recordedGesture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez enregistrer un mouvement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final spell = SpellModel(
        id: _existingSpell?.id ?? '',
        name: _nameController.text.trim(),
        gestureData: _recordedGesture!,
        voiceKeyword: _voiceController.text.trim(),
        beats: _existingSpell?.beats ?? '', // Conserver la relation existante
        soundFileUrl: _selectedSoundId, // 🆕 Ajouter l'URL du son
        createdAt: _existingSpell?.createdAt ?? DateTime.now(),
      );

      if (_existingSpell != null) {
        // Modification
        await SpellService.updateSpell(_existingSpell!.id, spell);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sort "${spell.name}" modifié !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Création
        await SpellService.createSpell(spell);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sort "${spell.name}" créé !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<String?> _getSoundUrlById(String soundId) async {
    try {
      final sound = await SoundService.getSoundById(soundId);
      return sound?.downloadUrl;
    } catch (e) {
      Logger.error(' Erreur récupération URL son: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingSpell != null;
    final title = isEditing ? 'Modifier le Sort' : 'Créer un Sort';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  _buildHeader(isEditing),
                  const SizedBox(height: 32),
                  
                  // Informations du sort
                  _buildSpellInfoSection(),
                  const SizedBox(height: 24),
                  
                  // 🆕 Section sélection du son
                  _buildSoundSelectionSection(),
                  const SizedBox(height: 32),
                  
                  // Section enregistrement gestuel
                  _buildGestureSection(),
                  const SizedBox(height: 32),
                  
                  // Boutons d'action
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEditing 
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Modifier le Sort' : 'Nouveau Sort',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isEditing 
                      ? 'Modifiez les propriétés et le mouvement'
                      : 'Créez un nouveau sort avec un mouvement unique',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du Sort',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom du sort',
              hintText: 'Ex: Boule de Feu',
              prefixIcon: const Icon(Icons.auto_fix_high),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom est obligatoire';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _voiceController,
            decoration: InputDecoration(
              labelText: 'Mot magique (optionnel)',
              hintText: 'Ex: Ignis',
              prefixIcon: const Icon(Icons.record_voice_over),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Bonus +0.5 point si prononcé pendant le duel',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mouvement du Sort',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Effectuez le mouvement que les joueurs devront reproduire',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          
          // Bouton d'enregistrement
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: GesturePatternService.isRecording ? _pulseAnimation.value : 1.0,
                  child: GestureDetector(
                    onTapDown: (_) => _startRecording(),
                    onTapUp: (_) => _stopRecording(),
                    onTapCancel: () => _stopRecording(),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: GesturePatternService.isRecording
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (GesturePatternService.isRecording ? Colors.red : Colors.blue)
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        GesturePatternService.isRecording ? Icons.stop : Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Instructions
          Center(
            child: Column(
              children: [
                Text(
                  GesturePatternService.isRecording 
                      ? 'Effectuez votre mouvement...'
                      : 'Maintenez pour enregistrer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GesturePatternService.isRecording ? Colors.red : Colors.blue,
                  ),
                ),
                if (GesturePatternService.isRecording) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(_recordingProgress / 1000).toStringAsFixed(1)}s / 5.0s',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _recordingProgress / 5000,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                  ),
                ],
              ],
            ),
          ),
          
          // Statut de l'enregistrement
          if (_recordedGesture != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mouvement enregistré !',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'Durée: ${(_recordedGesture!.duration / 1000).toStringAsFixed(1)}s • '
                          'Points: ${_recordedGesture!.accelerometerReadings.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _recordedGesture = null),
                    child: Text('Refaire', style: TextStyle(color: Colors.green.shade600)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSpell,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_existingSpell != null ? 'Modifier' : 'Créer'),
          ),
        ),
      ],
    );
  }

  Widget _buildSoundSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.audiotrack,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎵 Son du Sort',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Choisissez un son uploadé ou laissez vide pour un son générique',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/admin/sounds'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Gérer'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Liste des sons disponibles
          StreamBuilder<List<SoundFile>>(
            stream: SoundService.getSoundsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final sounds = snapshot.data ?? [];
              
              return Column(
                children: [
                  // Option "Aucun son spécifique"
                  _buildSoundOption(
                    isSelected: _selectedSoundId == null,
                    title: '🔇 Aucun son spécifique',
                    subtitle: 'Utiliser le son générique basé sur le nom',
                    onTap: () {
                      setState(() {
                        _selectedSoundId = null;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Sons uploadés disponibles
                  if (sounds.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.library_music, color: Colors.grey, size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            'Aucun son uploadé',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Allez dans "Gestion Sons" pour uploader des fichiers audio',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...sounds.map((sound) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildSoundOption(
                        isSelected: _selectedSoundId == sound.id,
                        title: '🎵 ${sound.name}',
                        subtitle: '${sound.originalFileName} • ${SoundService.formatFileSize(sound.fileSizeBytes)}',
                                                 onTap: () {
                           setState(() {
                             _selectedSoundId = sound.id;
                           });
                           // Jouer un aperçu du vrai son
                           AudioService().playSoundFromUrl(sound.downloadUrl);
                         },
                      ),
                    )),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSoundOption({
    required bool isSelected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.deepPurple.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? Colors.deepPurple
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.deepPurple : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected 
                          ? Colors.deepPurple.withValues(alpha: 0.7)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 