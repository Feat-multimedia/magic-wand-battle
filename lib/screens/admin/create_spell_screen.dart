import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/spell_model.dart';
import '../../services/spell_service.dart';
import '../../services/gesture_service.dart';

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
    GestureService.dispose();
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
    if (GestureService.isRecording) return;

    setState(() {
      _recordingProgress = 0;
      _recordedGesture = null;
    });
    
    _pulseController.repeat(reverse: true);

    try {
      await GestureService.startRecording(
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
    if (GestureService.isRecording) {
      GestureService.stopRecording();
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
                  scale: GestureService.isRecording ? _pulseAnimation.value : 1.0,
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
                          colors: GestureService.isRecording
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (GestureService.isRecording ? Colors.red : Colors.blue)
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        GestureService.isRecording ? Icons.stop : Icons.fiber_manual_record,
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
                  GestureService.isRecording 
                      ? 'Effectuez votre mouvement...'
                      : 'Maintenez pour enregistrer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GestureService.isRecording ? Colors.red : Colors.blue,
                  ),
                ),
                if (GestureService.isRecording) ...[
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
} 