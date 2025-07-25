import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_deployment_service.dart';

class FirebaseSetupScreen extends StatefulWidget {
  const FirebaseSetupScreen({super.key});

  @override
  State<FirebaseSetupScreen> createState() => _FirebaseSetupScreenState();
}

class _FirebaseSetupScreenState extends State<FirebaseSetupScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
  String _statusMessage = '';
  DeploymentResult? _lastDeployment;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final initialized = await FirebaseDeploymentService.isFirebaseInitialized();
      setState(() {
        _isInitialized = initialized;
        _statusMessage = initialized 
            ? 'Firebase est configuré et prêt ✅'
            : 'Firebase nécessite une initialisation ⚠️';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur lors de la vérification: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deployFirebase() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAdmin) {
      _showError('Seuls les administrateurs peuvent déployer la structure Firebase');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await FirebaseDeploymentService.deployFirebaseStructure();
      
      setState(() {
        _lastDeployment = result;
        _isInitialized = result.success;
        _statusMessage = result.success 
            ? 'Déploiement réussi ! 🎉'
            : 'Erreur de déploiement ❌';
      });

      if (result.success) {
        _showSuccessDialog(result);
      } else {
        _showError(result.message);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur lors du déploiement: $e';
      });
      _showError('Erreur lors du déploiement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetFirebase() async {
    final confirmed = await _showConfirmDialog(
      'Réinitialiser Firebase',
      'Attention ! Cette action supprimera TOUTES les données (sorts, arènes, matchs).\n\nCette action est irréversible. Continuer ?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseDeploymentService.resetFirebaseData();
      setState(() {
        _isInitialized = false;
        _statusMessage = 'Firebase réinitialisé - Redéploiement requis';
        _lastDeployment = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase réinitialisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la réinitialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Firebase'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Configuration Firebase',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Déploiement et gestion de la structure de base',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isInitialized ? Icons.check_circle : Icons.warning,
                              color: _isInitialized ? Colors.green : Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Statut Firebase',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statusMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_lastDeployment != null) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Dernier déploiement :',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _lastDeployment!.summary,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions principales
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Actions de déploiement',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        
                        // Déployer structure
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _deployFirebase,
                          icon: const Icon(Icons.rocket_launch),
                          label: Text(_isInitialized 
                              ? 'Redéployer la structure'
                              : 'Déployer la structure Firebase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Vérifier status
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _checkFirebaseStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Vérifier le statut'),
                        ),
                        const SizedBox(height: 12),
                        
                        // Reset (dangereux)
                        OutlinedButton.icon(
                          onPressed: _isLoading || !_isInitialized ? null : _resetFirebase,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Réinitialiser Firebase'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Informations de déploiement
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Que déploie cette action ?',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        
                        _buildInfoItem(
                          context,
                          Icons.auto_fix_high,
                          '6 Sorts par défaut',
                          'Fireball, Ice Shield, Lightning Bolt, Earth Quake, Wind Blade, Shadow Strike',
                        ),
                        _buildInfoItem(
                          context,
                          Icons.stadium,
                          'Arène de démonstration',
                          'Une arène d\'exhibition prête à utiliser',
                        ),
                        _buildInfoItem(
                          context,
                          Icons.people,
                          'Utilisateurs de test',
                          'Comptes de démonstration pour tester les fonctionnalités',
                        ),
                        _buildInfoItem(
                          context,
                          Icons.settings,
                          'Système chifoumi',
                          'Relations circulaires entre les sorts (A > B > C > ... > F > A)',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessDialog(DeploymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Déploiement réussi !'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(result.summary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
} 