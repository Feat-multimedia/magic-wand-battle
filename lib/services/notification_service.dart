import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// 🔔 **Service de gestion des notifications**
/// Support multi-plateforme avec désactivation automatique sur le web
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Services (null sur le web)
  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  
  // Navigation globale
  static GlobalKey<NavigatorState>? _globalNavigatorKey;
  
  // État
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isSupported => !kIsWeb;

  /// 🚀 **Initialiser le service de notifications**
  Future<void> initialize() async {
    try {
      Logger.info('🔔 Initialisation NotificationService...');
      
      if (kIsWeb) {
        Logger.info('🌐 Notifications désactivées sur le web');
        _isInitialized = true;
        return;
      }

      // Initialisation mobile uniquement
      _messaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();
      
      // Configuration basique
      await _requestPermissions();
      await _initializeLocalNotifications();
      
      _isInitialized = true;
      Logger.success('✅ NotificationService initialisé');
      
    } catch (e) {
      Logger.error('❌ Erreur initialisation NotificationService', error: e);
      _isInitialized = false;
    }
  }

  /// 📱 **Demander les permissions**
  Future<void> _requestPermissions() async {
    if (kIsWeb || _messaging == null) return;
    
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// 🔔 **Initialiser les notifications locales**
  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb || _localNotifications == null) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 👆 **Gestion du tap sur notification**
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (kIsWeb) return;
    
    Logger.info('👆 Notification tappée: ${response.payload}');
    // Navigation basique vers l'accueil
    _navigateToHome();
  }

  /// 🏠 **Navigation vers l'accueil**
  Future<void> _navigateToHome() async {
    if (_globalNavigatorKey?.currentState != null) {
      _globalNavigatorKey!.currentState!.pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// 🗝️ **Définir la clé de navigation globale**
  static void setGlobalNavigatorKey(GlobalKey<NavigatorState> key) {
    _globalNavigatorKey = key;
  }

  /// 📤 **Envoyer une notification (version simplifiée)**
  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (kIsWeb) {
      Logger.info('🌐 Notification ignorée sur le web: $title');
      return;
    }
    
    Logger.info('📤 Notification pour $userId: $title');
    // TODO: Implémenter l'envoi FCM réel
  }

  /// ⚔️ **Notifier un nouveau match**
  Future<void> notifyNewMatch({
    required String playerId,
    required String opponentName,
    required String arenaName,
  }) async {
    await sendPushNotification(
      userId: playerId,
      title: '⚔️ Nouveau Duel !',
      body: 'Vous affrontez $opponentName dans l\'arène $arenaName',
      data: {
        'type': 'new_match',
        'opponentName': opponentName,
        'arenaName': arenaName,
      },
    );
  }

  /// 🎉 **Notifier une victoire**
  Future<void> notifyVictory({
    required String playerId,
    required String opponentName,
    required double score,
  }) async {
    await sendPushNotification(
      userId: playerId,
      title: '🎉 Victoire !',
      body: 'Vous avez vaincu $opponentName avec ${score.toStringAsFixed(1)} points !',
      data: {
        'type': 'victory',
        'opponentName': opponentName,
        'score': score.toString(),
      },
    );
  }

  /// 😔 **Notifier une défaite**
  Future<void> notifyDefeat({
    required String playerId,
    required String opponentName,
    required double score,
  }) async {
    await sendPushNotification(
      userId: playerId,
      title: '⚔️ Match terminé',
      body: 'Défaite contre $opponentName. Score: ${score.toStringAsFixed(1)} points',
      data: {
        'type': 'defeat',
        'opponentName': opponentName,
        'score': score.toString(),
      },
    );
  }

  /// 👑 **Notifier les admins d'un nouveau joueur**
  Future<void> notifyAdminNewPlayer({
    required String playerName,
    required String playerEmail,
  }) async {
    // TODO: Récupérer la liste des admins depuis Firestore
    Logger.info('👑 Nouveau joueur: $playerName ($playerEmail)');
    
    // Pour l'instant, juste un log
    // Dans une vraie implémentation, on enverrait la notification à tous les admins
  }

  /// 🔔 **Afficher une notification locale**
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || _localNotifications == null) {
      Logger.info('🌐 Notification locale ignorée sur le web: $title');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'magic_wand_battle',
      'Magic Wand Battle',
      channelDescription: 'Notifications du jeu Magic Wand Battle',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 🧹 **Nettoyer les ressources**
  void dispose() {
    if (!kIsWeb) {
      Logger.info('🧹 NotificationService dispose');
    }
  }
} 