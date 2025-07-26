import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import '../models/models.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Stream de l'état d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté
  static User? get currentUser => _auth.currentUser;

  /// Vérifie si un utilisateur est connecté
  static bool get isLoggedIn => currentUser != null;

  /// Connexion avec email et mot de passe
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Vérifier si le profil utilisateur existe dans Firestore
      await _ensureUserProfileExists(credential.user!);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  /// Inscription avec email et mot de passe
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    bool isAdmin = false,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Mettre à jour le profil Firebase
      await credential.user!.updateDisplayName(displayName);

      // Créer le profil utilisateur dans Firestore
      await _createUserProfile(
        credential.user!,
        displayName: displayName,
        isAdmin: isAdmin,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  /// Déconnexion
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur de déconnexion: $e');
    }
  }

  /// Réinitialisation du mot de passe
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur de réinitialisation: $e');
    }
  }

  /// Obtenir le profil utilisateur depuis Firestore
  static Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        // Créer le profil s'il n'existe pas
        await _ensureUserProfileExists(user);
        return getCurrentUserProfile();
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// Stream du profil utilisateur actuel
  static Stream<UserModel?> getCurrentUserProfileStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  /// 📝 **Mettre à jour le profil utilisateur**
  static Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Mise à jour dans Firebase Auth
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Mise à jour dans Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.success('Profil utilisateur mis à jour');
      return true;
    } catch (e) {
      Logger.error('Erreur mise à jour profil', error: e);
      return false;
    }
  }

  /// Vérifier si l'utilisateur actuel est administrateur
  static Future<bool> isCurrentUserAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?.isAdmin ?? false;
  }

  /// Créer le profil utilisateur dans Firestore
  static Future<void> _createUserProfile(
    User user, {
    required String displayName,
    bool isAdmin = false,
  }) async {
    final userModel = UserModel(
      id: user.uid,
      displayName: displayName,
      email: user.email ?? '',
      isAdmin: isAdmin,
      stats: UserStats(
        matchsPlayed: 0,
        totalPoints: 0.0,
        spellsUsed: {},
        successRate: 0.0,
      ),
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore());
  }

  /// S'assurer que le profil utilisateur existe
  static Future<void> _ensureUserProfileExists(User user) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      await _createUserProfile(
        user,
        displayName: user.displayName ?? 'Sorcier ${user.uid.substring(0, 6)}',
      );
    }
  }

  /// Gérer les exceptions d'authentification Firebase
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'operation-not-allowed':
        return 'Opération non autorisée.';
      case 'invalid-credential':
        return 'Identifiants invalides.';
      case 'network-request-failed':
        return 'Erreur de connexion réseau.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      default:
        return e.message ?? 'Erreur d\'authentification inconnue.';
    }
  }
} 