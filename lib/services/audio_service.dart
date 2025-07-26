import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../utils/logger.dart';

/// Types de sons dans le jeu
enum SoundType {
  // Sons de sorts
  fireball,
  iceBlast,
  lightning,
  heal,
  shield,
  meteor,
  
  // Sons d'interface
  spellCast,
  spellSuccess,
  spellFail,
  victory,
  defeat,
  
  // Sons d'ambiance
  backgroundMusic,
  duelStart,
  countdown,
  
  // Sons d'interface
  buttonClick,
  notification,
  whoosh,
}

/// Service audio pour gérer tous les sons du jeu
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Players pour différents types de sons
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  
  // État audio
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  double _sfxVolume = 0.7;
  double _musicVolume = 0.3;
  
  // Cache des sons préchargés
  final Map<SoundType, String> _soundPaths = {};
  
  /// Initialiser le service audio
  Future<void> initialize() async {
    try {
      // Configurer les chemins des fichiers audio
      _setupSoundPaths();
      
      // Configurer les players
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _voicePlayer.setReleaseMode(ReleaseMode.stop);
      
      Logger.audio(' AudioService initialisé', tag: LogTags.audio);
    } catch (e) {
      Logger.error(' Erreur initialisation audio: $e');
    }
  }

  /// Configurer les chemins des sons
  void _setupSoundPaths() {
    _soundPaths[SoundType.fireball] = 'sounds/spells/fireball.mp3';
    _soundPaths[SoundType.iceBlast] = 'sounds/spells/ice_blast.mp3';
    _soundPaths[SoundType.lightning] = 'sounds/spells/lightning.mp3';
    _soundPaths[SoundType.heal] = 'sounds/spells/heal.mp3';
    _soundPaths[SoundType.shield] = 'sounds/spells/shield.mp3';
    _soundPaths[SoundType.meteor] = 'sounds/spells/meteor.mp3';
    
    _soundPaths[SoundType.spellCast] = 'sounds/effects/spell_cast.mp3';
    _soundPaths[SoundType.spellSuccess] = 'sounds/effects/spell_success.mp3';
    _soundPaths[SoundType.spellFail] = 'sounds/effects/spell_fail.mp3';
    _soundPaths[SoundType.victory] = 'sounds/effects/victory.mp3';
    _soundPaths[SoundType.defeat] = 'sounds/effects/defeat.mp3';
    
    _soundPaths[SoundType.backgroundMusic] = 'sounds/music/battle_theme.mp3';
    _soundPaths[SoundType.duelStart] = 'sounds/effects/duel_start.mp3';
    _soundPaths[SoundType.countdown] = 'sounds/effects/countdown.mp3';
    
    _soundPaths[SoundType.buttonClick] = 'sounds/ui/button_click.mp3';
    _soundPaths[SoundType.notification] = 'sounds/ui/notification.mp3';
    _soundPaths[SoundType.whoosh] = 'sounds/ui/whoosh.mp3';
  }

  /// Jouer un effet sonore
  Future<void> playSFX(SoundType soundType, {double? volume}) async {
    if (!_sfxEnabled) return;
    
    try {
      final path = _soundPaths[soundType];
      if (path == null) {
        // Utiliser un son de substitution générique
        await _playFallbackSound(soundType);
        return;
      }
      
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(volume ?? _sfxVolume);
      await _sfxPlayer.play(AssetSource(path));
      
      // Ajouter vibration pour certains sons
      _addHapticFeedback(soundType);
      
    } catch (e) {
      Logger.error(' Erreur lecture SFX $soundType: $e');
      // Jouer un son de substitution
      await _playFallbackSound(soundType);
    }
  }

  /// Jouer un son de sort spécifique
  Future<void> playSpellSound(String spellName, {double? volume}) async {
    if (!_sfxEnabled) return;
    
    // Mapper les noms de sorts aux sons
    SoundType? soundType;
    
    final lowerSpellName = spellName.toLowerCase();
    if (lowerSpellName.contains('fire') || lowerSpellName.contains('feu')) {
      soundType = SoundType.fireball;
    } else if (lowerSpellName.contains('ice') || lowerSpellName.contains('glace')) {
      soundType = SoundType.iceBlast;
    } else if (lowerSpellName.contains('lightning') || lowerSpellName.contains('foudre')) {
      soundType = SoundType.lightning;
    } else if (lowerSpellName.contains('heal') || lowerSpellName.contains('soin')) {
      soundType = SoundType.heal;
    } else if (lowerSpellName.contains('shield') || lowerSpellName.contains('bouclier')) {
      soundType = SoundType.shield;
    } else if (lowerSpellName.contains('meteor') || lowerSpellName.contains('météore')) {
      soundType = SoundType.meteor;
    }
    
    if (soundType != null) {
      await playSFX(soundType, volume: volume);
    } else {
      // Son générique de sort
      await playSFX(SoundType.spellCast, volume: volume);
    }
  }

  /// 🆕 Jouer un son de sort par type direct
  Future<void> playSpellSoundByType(String soundType, {double? volume}) async {
    if (!_sfxEnabled) return;
    
    // Convertir le string vers SoundType
    SoundType? sound = _stringToSoundType(soundType);
    
    if (sound != null) {
      await playSFX(sound, volume: volume);
    } else {
      // Son générique de sort si type non reconnu
      await playSFX(SoundType.spellCast, volume: volume);
    }
  }

  /// 🆕 Convertir un string vers SoundType
  SoundType? _stringToSoundType(String soundTypeString) {
    switch (soundTypeString.toLowerCase()) {
      case 'fireball':
        return SoundType.fireball;
      case 'iceblast':
        return SoundType.iceBlast;
      case 'lightning':
        return SoundType.lightning;
      case 'heal':
        return SoundType.heal;
      case 'shield':
        return SoundType.shield;
      case 'meteor':
        return SoundType.meteor;
      case 'spellcast':
      default:
        return SoundType.spellCast;
    }
  }

  /// 🆕 Jouer un son depuis une URL (pour les sons uploadés)
  Future<void> playSoundFromUrl(String url, {double? volume}) async {
    if (!_sfxEnabled) return;
    
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(volume ?? _sfxVolume);
      await _sfxPlayer.play(UrlSource(url));
      
      Logger.audio(' Lecture son depuis URL: $url', tag: LogTags.audio);
    } catch (e) {
      Logger.error(' Erreur lecture son URL: $e');
      // Fallback sur son générique
      await playSFX(SoundType.spellCast, volume: volume);
    }
  }

  /// 🆕 Obtenir la liste des types de sons disponibles
  static List<Map<String, String>> getAvailableSoundTypes() {
    return [
      {'key': 'fireball', 'name': '🔥 Feu', 'description': 'Son d\'attaque de feu'},
      {'key': 'iceblast', 'name': '❄️ Glace', 'description': 'Son d\'attaque de glace'},
      {'key': 'lightning', 'name': '⚡ Foudre', 'description': 'Son d\'attaque de foudre'},
      {'key': 'heal', 'name': '💚 Soin', 'description': 'Son de guérison'},
      {'key': 'shield', 'name': '🛡️ Bouclier', 'description': 'Son de protection'},
      {'key': 'meteor', 'name': '☄️ Météore', 'description': 'Son d\'impact cosmique'},
      {'key': 'spellcast', 'name': '🎯 Générique', 'description': 'Son de sort générique'},
    ];
  }

  /// Jouer la musique de fond
  Future<void> playBackgroundMusic({double? volume}) async {
    if (!_musicEnabled) return;
    
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setVolume(volume ?? _musicVolume);
      await _musicPlayer.play(AssetSource(_soundPaths[SoundType.backgroundMusic]!));
    } catch (e) {
      Logger.error(' Erreur lecture musique: $e');
    }
  }

  /// Arrêter la musique de fond
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  /// Jouer le son de victoire avec séquence complète
  Future<void> playVictorySequence() async {
    if (!_sfxEnabled) return;
    
    try {
      // Son de victoire
      await playSFX(SoundType.victory, volume: 0.8);
      
      // Vibration de célébration
      await _celebrationVibration();
      
      // Feedback haptique iOS
      await HapticFeedback.heavyImpact();
      
    } catch (e) {
      Logger.error(' Erreur séquence victoire: $e');
    }
  }

  /// Jouer le son de défaite
  Future<void> playDefeatSequence() async {
    if (!_sfxEnabled) return;
    
    try {
      await playSFX(SoundType.defeat, volume: 0.6);
      await HapticFeedback.lightImpact();
    } catch (e) {
      Logger.error(' Erreur séquence défaite: $e');
    }
  }

  /// Jouer une séquence de compte à rebours
  Future<void> playCountdownSequence() async {
    if (!_sfxEnabled) return;
    
    for (int i = 3; i >= 1; i--) {
      await playSFX(SoundType.countdown, volume: 0.8);
      await Future.delayed(const Duration(seconds: 1));
    }
    
    // Son de début
    await playSFX(SoundType.duelStart, volume: 1.0);
    await HapticFeedback.heavyImpact();
  }

  /// Jouer un son de substitution généré
  Future<void> _playFallbackSound(SoundType soundType) async {
    try {
      // Utiliser des tonalités système pour simuler les sons
      switch (soundType) {
        case SoundType.spellSuccess:
          await HapticFeedback.heavyImpact();
          await SystemSound.play(SystemSoundType.click);
          break;
        case SoundType.spellFail:
          await HapticFeedback.lightImpact();
          break;
        case SoundType.victory:
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          break;
        case SoundType.buttonClick:
          await HapticFeedback.selectionClick();
          break;
        default:
          await HapticFeedback.lightImpact();
      }
    } catch (e) {
      Logger.error(' Erreur son de substitution: $e');
    }
  }

  /// Ajouter un feedback haptique basé sur le son
  Future<void> _addHapticFeedback(SoundType soundType) async {
    try {
      switch (soundType) {
        case SoundType.fireball:
        case SoundType.lightning:
        case SoundType.meteor:
          await HapticFeedback.heavyImpact();
          break;
        case SoundType.iceBlast:
        case SoundType.shield:
          await HapticFeedback.mediumImpact();
          break;
        case SoundType.heal:
          await HapticFeedback.lightImpact();
          break;
        case SoundType.spellSuccess:
          await HapticFeedback.mediumImpact();
          break;
        case SoundType.spellFail:
          // Vibration d'erreur personnalisée
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(pattern: [100, 50, 100, 50, 200]);
          }
          break;
        case SoundType.buttonClick:
          await HapticFeedback.selectionClick();
          break;
        default:
          break;
      }
    } catch (e) {
      Logger.error(' Erreur haptic feedback: $e');
    }
  }

  /// Vibration de célébration
  Future<void> _celebrationVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Pattern de vibration joyeux
        Vibration.vibrate(pattern: [100, 50, 100, 50, 200]);
      }
    } catch (e) {
      Logger.error(' Erreur vibration célébration: $e');
    }
  }

  // Contrôles audio
  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;
  double get sfxVolume => _sfxVolume;
  double get musicVolume => _musicVolume;

  set sfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    if (!enabled) {
      _sfxPlayer.stop();
    }
  }

  set musicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _musicPlayer.stop();
    } else {
      playBackgroundMusic();
    }
  }

  set sfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
    _sfxPlayer.setVolume(_sfxVolume);
  }

  set musicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _musicPlayer.setVolume(_musicVolume);
  }

  /// Nettoyer les ressources
  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _musicPlayer.dispose();
    await _voicePlayer.dispose();
  }

  /// Créer des assets audio factices pour le développement
  static Future<void> createDummyAudioAssets() async {
    // En développement, cette méthode pourrait être utilisée
    // pour créer des assets audio de test
    Logger.audio(' Mode développement: Assets audio simulés', tag: LogTags.audio);
  }
} 