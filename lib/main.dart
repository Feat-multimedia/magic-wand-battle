import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'services/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'constants/app_constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/spell_management_screen.dart';
import 'screens/admin/create_spell_screen.dart';
import 'screens/game/duel_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MagicWandBattleApp());
}

class MagicWandBattleApp extends StatelessWidget {
  const MagicWandBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Afficher l'écran de chargement tant que Firebase n'est pas initialisé
          if (!authProvider.isInitialized) {
            return MaterialApp(
              title: AppConstants.appName,
              theme: _buildTheme(),
              home: const LoadingScreen(),
              debugShowCheckedModeBanner: false,
            );
          }
          
          // Une fois initialisé, utiliser le router normal
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: _buildTheme(),
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6), // Bleu moderne
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF3B82F6), // Bleu principal
        secondary: const Color(0xFF10B981), // Vert émeraude
        tertiary: const Color(0xFF8B5CF6), // Violet accent
        surface: const Color(0xFFFFFFFF), // Blanc pur
        surfaceContainerHighest: const Color(0xFFF8FAFC), // Gris ultra-clair
        onSurface: const Color(0xFF0F172A), // Texte très sombre
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Fond ultra-clair
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.25,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: AppConstants.loginRoute,
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;
    final isLoginPage = state.fullPath == AppConstants.loginRoute;

    // Si pas connecté et pas sur la page de login, rediriger vers login
    if (!isLoggedIn && !isLoginPage) {
      return AppConstants.loginRoute;
    }

    // Si connecté et sur la page de login, rediriger vers home
    if (isLoggedIn && isLoginPage) {
      return AppConstants.homeRoute;
    }

    return null;
  },

  routes: [
    GoRoute(
      path: AppConstants.loginRoute,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppConstants.homeRoute,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppConstants.profileRoute,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppConstants.adminRoute,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/spells',
      builder: (context, state) => const SpellManagementScreen(),
    ),
    GoRoute(
      path: '/admin/spells/create',
      builder: (context, state) => const CreateSpellScreen(),
    ),
    GoRoute(
      path: '/admin/spells/edit/:spellId',
      builder: (context, state) {
        final spellId = state.pathParameters['spellId'];
        return CreateSpellScreen(spellId: spellId);
      },
    ),
    GoRoute(
      path: '/duel/:matchId/:playerId',
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? '';
        final playerId = state.pathParameters['playerId'] ?? '';
        return DuelScreen(matchId: matchId, playerId: playerId);
      },
    ),
  ],
  refreshListenable: GoRouterRefreshStream(
    FirebaseService.authStateChanges,
  ),
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
