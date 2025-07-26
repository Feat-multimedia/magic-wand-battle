import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/create_spell_screen.dart';
import 'screens/admin/spell_management_screen.dart';
import 'screens/admin/firebase_setup_screen.dart';
import 'screens/debug/gesture_debug_screen.dart';
import 'screens/admin/arena_management_screen.dart';
import 'screens/admin/tournament_management_screen.dart';
import 'screens/tournaments/tournament_list_screen.dart';
import 'screens/tournaments/bracket_viewer_screen.dart';
import 'screens/tournaments/tournament_details_screen.dart';
import 'screens/tournaments/tournament_results_screen.dart';
import 'screens/admin/sound_management_screen.dart';
import 'screens/admin/game_master_screen.dart';
import 'screens/admin/projection_screen.dart';
import 'screens/profile/leaderboard_screen.dart';
import 'screens/game/duel_screen.dart';
import 'services/notification_service.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/tournaments/live_tournament_screen.dart';
import 'screens/profile/edit_profile_screen.dart';

// Clé globale pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialiser les notifications (seulement sur mobile)
  if (!kIsWeb) {
    NotificationService.setGlobalNavigatorKey(navigatorKey);
    await NotificationService().initialize();
  }
  
  runApp(const MagicWandBattleApp());
}

class MagicWandBattleApp extends StatelessWidget {
  const MagicWandBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp.router(
        title: 'Magic Wand Battle',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/admin',
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
      path: '/admin/firebase-setup',
      builder: (context, state) => const FirebaseSetupScreen(),
    ),
    GoRoute(
      path: '/admin/arenas',
      builder: (context, state) => const ArenaManagementScreen(),
    ),
    GoRoute(
      path: '/admin/tournaments',
      builder: (context, state) => const TournamentManagementScreen(),
    ),
    GoRoute(
      path: '/tournaments',
      builder: (context, state) => const TournamentListScreen(),
    ),
    GoRoute(
      path: '/tournaments/:id/bracket',
      builder: (context, state) {
        final tournamentId = state.pathParameters['id']!;
        return BracketViewerScreen(tournamentId: tournamentId);
      },
    ),
    GoRoute(
      path: '/tournaments/:id/live',
      builder: (context, state) {
        final tournamentId = state.pathParameters['id']!;
        return LiveTournamentScreen(tournamentId: tournamentId);
      },
    ),
    GoRoute(
      path: '/tournaments/:id/details',
      builder: (context, state) {
        final tournamentId = state.pathParameters['id']!;
        return TournamentDetailsScreen(tournamentId: tournamentId);
      },
    ),
    GoRoute(
      path: '/tournaments/:id/results',
      builder: (context, state) {
        final tournamentId = state.pathParameters['id']!;
        return TournamentResultsScreen(tournamentId: tournamentId);
      },
    ),
    GoRoute(
      path: '/admin/sounds',
      builder: (context, state) => const SoundManagementScreen(),
    ),
    GoRoute(
      path: '/admin/game-master',
      builder: (context, state) => const GameMasterScreen(),
    ),
    GoRoute(
      path: '/projection',
      builder: (context, state) => const ProjectionScreen(),
    ),
    GoRoute(
      path: '/projection/:matchId',
      builder: (context, state) {
        final matchId = state.pathParameters['matchId']!;
        return ProjectionScreen(specificMatchId: matchId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/game/duel/:matchId/:playerId',
      builder: (context, state) {
        final matchId = state.pathParameters['matchId']!;
        final playerId = state.pathParameters['playerId']!;
        return DuelScreen(matchId: matchId, playerId: playerId);
      },
    ),
    GoRoute(
      path: '/duel/training/solo',
      builder: (context, state) => const DuelScreen(matchId: 'training', playerId: 'solo'),
    ),
    GoRoute(
      path: '/training',
      builder: (context, state) => const DuelScreen(matchId: 'training', playerId: 'solo'),
    ),
    GoRoute(
      path: '/debug/gestures',
      builder: (context, state) => const GestureDebugScreen(),
    ),
  ],
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
