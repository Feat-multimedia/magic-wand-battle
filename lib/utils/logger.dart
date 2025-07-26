import 'dart:developer' as developer;

/// 📋 **Logger** - Système de logging propre pour remplacer les print()
/// 
/// **Avantages :**
/// - Contrôle du niveau de log (debug, info, warning, error)
/// - Filtrage par tag/contexte
/// - Désactivation en production
/// - Format uniforme et lisible
class Logger {
  static const bool _kDebugMode = true; // À désactiver en production
  
  /// 🐛 **Debug** - Informations de développement
  static void debug(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('🐛 DEBUG', message, tag: tag);
  }
  
  /// ℹ️ **Info** - Informations générales
  static void info(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('ℹ️ INFO', message, tag: tag);
  }
  
  /// ⚠️ **Warning** - Avertissements
  static void warning(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('⚠️ WARN', message, tag: tag);
  }
  
  /// ❌ **Error** - Erreurs
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('❌ ERROR', message, tag: tag);
    if (error != null) {
      developer.log(
        'Error details: $error',
        name: tag ?? 'MagicWandBattle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// 🚀 **Success** - Opérations réussies
  static void success(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('✅ SUCCESS', message, tag: tag);
  }
  
  /// 🔔 **Notification** - Événements de notifications
  static void notification(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('🔔 NOTIF', message, tag: tag);
  }
  
  /// 🎮 **Game** - Événements de jeu
  static void game(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('🎮 GAME', message, tag: tag);
  }
  
  /// 🎵 **Audio** - Événements audio
  static void audio(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('🎵 AUDIO', message, tag: tag);
  }
  
  /// 🔥 **Firebase** - Événements Firebase
  static void firebase(String message, {String? tag}) {
    if (!_kDebugMode) return;
    _log('🔥 FIREBASE', message, tag: tag);
  }
  
  /// 🏗️ **Internal logging method**
  static void _log(String level, String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final tagStr = tag != null ? ' [$tag]' : '';
    final logMessage = '$timestamp $level$tagStr: $message';
    
    developer.log(
      logMessage,
      name: tag ?? 'MagicWandBattle',
    );
  }
  
  /// 🧹 **Méthodes utilitaires**
  
  /// Loguer une opération avec durée
  static void timed(String operation, Duration duration, {String? tag}) {
    info('$operation completed in ${duration.inMilliseconds}ms', tag: tag);
  }
  
  /// Loguer le début et la fin d'une opération
  static void operation(String operation, {String? tag}) {
    info('Starting: $operation', tag: tag);
  }
  
  /// Loguer une méthode/fonction
  static void method(String className, String methodName, {String? details}) {
    debug('$className.$methodName${details != null ? ' - $details' : ''}', 
          tag: className);
  }
  
  /// Loguer un état/statut
  static void status(String component, String status, {String? tag}) {
    info('$component: $status', tag: tag ?? component);
  }
}

/// 🏷️ **Tags prédéfinis pour organiser les logs**
class LogTags {
  static const String auth = 'Auth';
  static const String arena = 'Arena';
  static const String spell = 'Spell';
  static const String match = 'Match';
  static const String gesture = 'Gesture';
  static const String voice = 'Voice';
  static const String audio = 'Audio';
  static const String notification = 'Notification';
  static const String firebase = 'Firebase';
  static const String ui = 'UI';
  static const String navigation = 'Navigation';
  static const String admin = 'Admin';
  static const String gamemaster = 'GameMaster';
  static const String stats = 'Stats';
  static const String storage = 'Storage';
  static const String game = 'Game'; // 🎮 Tag manquant ajouté
} 