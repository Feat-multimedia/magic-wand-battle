import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../widgets/common_widgets.dart';

/// Écran de paramètres audio
class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Paramètres Audio'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            const SizedBox(height: 24),
            _buildVolumeSettings(),
            const SizedBox(height: 24),
            _buildSoundTestSection(),
            const SizedBox(height: 24),
            _buildSpellSoundsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return SoundCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Paramètres Généraux',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SoundSwitch(
              value: _audioService.sfxEnabled,
              onChanged: (value) {
                setState(() {
                  _audioService.sfxEnabled = value;
                });
              },
              label: '🔊 Effets Sonores',
            ),
            SoundSwitch(
              value: _audioService.musicEnabled,
              onChanged: (value) {
                setState(() {
                  _audioService.musicEnabled = value;
                });
              },
              label: '🎵 Musique de Fond',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSettings() {
    return SoundCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔊 Contrôles de Volume',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SoundSlider(
              value: _audioService.sfxVolume,
              onChanged: (value) {
                setState(() {
                  _audioService.sfxVolume = value;
                });
              },
              label: '🎯 Volume des Effets (${(_audioService.sfxVolume * 100).round()}%)',
            ),
            const SizedBox(height: 16),
            SoundSlider(
              value: _audioService.musicVolume,
              onChanged: (value) {
                setState(() {
                  _audioService.musicVolume = value;
                });
              },
              label: '🎼 Volume de la Musique (${(_audioService.musicVolume * 100).round()}%)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundTestSection() {
    return SoundCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎧 Test des Sons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton('🔘 Clic', SoundType.buttonClick),
                _buildTestButton('✨ Whoosh', SoundType.whoosh),
                _buildTestButton('✅ Succès', SoundType.spellSuccess),
                _buildTestButton('❌ Échec', SoundType.spellFail),
                _buildTestButton('🏆 Victoire', SoundType.victory),
                _buildTestButton('😔 Défaite', SoundType.defeat),
              ],
            ),
            const SizedBox(height: 16),
            HeroSoundButton(
              text: 'Test Complet',
              icon: Icons.play_circle_filled,
              color: Colors.purple,
              onPressed: _playFullTestSequence,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellSoundsSection() {
    return SoundCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Sons de Sorts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSpellTestButton('🔥 Feu', 'Ignis'),
                _buildSpellTestButton('❄️ Glace', 'Glacius'),
                _buildSpellTestButton('⚡ Foudre', 'Fulguris'),
                _buildSpellTestButton('💚 Soin', 'Sanitas'),
                _buildSpellTestButton('🛡️ Bouclier', 'Protego'),
                _buildSpellTestButton('☄️ Météore', 'Meteorus'),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les sons de sorts s\'adaptent automatiquement selon l\'incantation reconnue.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, SoundType soundType) {
    return SoundButton(
      text: label,
      onPressed: () => _audioService.playSFX(soundType),
      customSound: null, // Ne pas jouer le son par défaut du bouton
    );
  }

  Widget _buildSpellTestButton(String label, String spellName) {
    return SoundButton(
      text: label,
      onPressed: () => _audioService.playSpellSound(spellName),
      backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
      foregroundColor: Colors.deepPurple,
      customSound: null,
    );
  }

  Future<void> _playFullTestSequence() async {
    SoundNotification.show(
      context,
      message: '🎵 Démarrage du test audio complet...',
      sound: SoundType.notification,
    );

    // Séquence de test dramatique
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Test des effets
    await _audioService.playSFX(SoundType.whoosh);
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Test d'un sort
    await _audioService.playSpellSound('Ignis');
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Test du succès
    await _audioService.playSFX(SoundType.spellSuccess);
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Test de la victoire
    await _audioService.playVictorySequence();
    
    if (mounted) {
      SoundNotification.show(
        context,
        message: '✅ Test audio terminé !',
        backgroundColor: Colors.green,
      );
    }
  }
} 