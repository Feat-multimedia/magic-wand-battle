import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/notification_service.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/logger.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _matchNotifications = true;
  bool _resultNotifications = true;
  bool _adminNotifications = false;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      // Pour le web, les notifications sont désactivées
      if (kIsWeb) {
        setState(() {
          _notificationsEnabled = false;
        });
        return;
      }
      
      // Sur mobile, récupérer l'état du service
      setState(() {
        _notificationsEnabled = _notificationService.isSupported && _notificationService.isInitialized;
      });
      
    } catch (e) {
      Logger.error('Erreur chargement paramètres notifications', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Notifications'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information sur le support
            if (kIsWeb) ...[
              SoundCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade600,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications Web',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Les notifications push ne sont pas disponibles sur la version web. Utilisez l\'application mobile pour recevoir les notifications.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Paramètres de notifications (mobile uniquement)
            if (!kIsWeb) ...[
              _buildNotificationSettings(),
              const SizedBox(height: 24),
              _buildNotificationTypes(),
              const SizedBox(height: 24),
              _buildTestSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return SoundCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres généraux',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Activer les notifications'),
              subtitle: Text(
                _notificationsEnabled 
                  ? 'Les notifications sont activées'
                  : 'Les notifications sont désactivées',
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                // TODO: Sauvegarder la préférence utilisateur
              },
              secondary: Icon(
                _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                color: _notificationsEnabled ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return SoundCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Types de notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            SwitchListTile(
              title: const Text('Nouveaux matchs'),
              subtitle: const Text('Notification quand un match vous est assigné'),
              value: _matchNotifications && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _matchNotifications = value;
                });
              } : null,
              secondary: Icon(
                Icons.sports_kabaddi,
                color: _matchNotifications && _notificationsEnabled ? Colors.blue : Colors.grey,
              ),
            ),
            
            SwitchListTile(
              title: const Text('Résultats de matchs'),
              subtitle: const Text('Notification des résultats de vos matchs'),
              value: _resultNotifications && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _resultNotifications = value;
                });
              } : null,
              secondary: Icon(
                Icons.emoji_events,
                color: _resultNotifications && _notificationsEnabled ? Colors.amber : Colors.grey,
              ),
            ),
            
            SwitchListTile(
              title: const Text('Notifications admin'),
              subtitle: const Text('Annonces importantes et événements'),
              value: _adminNotifications && _notificationsEnabled,
              onChanged: _notificationsEnabled ? (value) {
                setState(() {
                  _adminNotifications = value;
                });
              } : null,
              secondary: Icon(
                Icons.admin_panel_settings,
                color: _adminNotifications && _notificationsEnabled ? Colors.purple : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return SoundCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test des notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Testez si les notifications fonctionnent sur votre appareil.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _notificationsEnabled ? _testNotification : null,
                icon: const Icon(Icons.notifications),
                label: const Text('Tester une notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.showLocalNotification(
        title: '🧙‍♂️ Magic Wand Battle',
        body: 'Test de notification réussi ! ✨',
        payload: 'test',
      );
      
      if (mounted) {
        SoundNotification.show(
          context,
          message: '📱 Notification de test envoyée !',
        );
      }
    } catch (e) {
      Logger.error('Erreur test notification', error: e);
      if (mounted) {
        SoundNotification.show(
          context,
          message: '❌ Erreur lors du test de notification',
        );
      }
    }
  }
} 