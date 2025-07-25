import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configuration Firestore pour mode offline
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  /// Vérifie si l'utilisateur actuel est connecté
  static bool get isUserLoggedIn => auth.currentUser != null;
  
  /// Obtient l'ID de l'utilisateur actuel
  static String? get currentUserId => auth.currentUser?.uid;
  
  /// Obtient l'email de l'utilisateur actuel
  static String? get currentUserEmail => auth.currentUser?.email;
  
  /// Stream des changements d'authentification
  static Stream<User?> get authStateChanges => auth.authStateChanges();
} 