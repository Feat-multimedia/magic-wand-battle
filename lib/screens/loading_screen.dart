import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Attendre un petit délai pour l'animation de chargement
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;

      // Obtenir l'AuthProvider
      final authProvider = context.read<AuthProvider>();
      
      // Attendre que l'AuthProvider soit initialisé
      while (!authProvider.isInitialized && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (!mounted) return;

      // Vérifier l'état d'authentification
      if (authProvider.isAuthenticated) {
        // Utilisateur connecté
        if (mounted) {
          context.go('/home');
        }
      } else {
        // Utilisateur non connecté
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      Logger.error('Erreur lors de la vérification d\'authentification', error: e);
      // En cas d'erreur, rediriger vers login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_fix_high,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Titre
            Text(
              'Magic Wand Battle',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Indicateur de chargement
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Initialisation...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 