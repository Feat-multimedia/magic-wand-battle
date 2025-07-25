import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false; // Nouveau flag pour l'initialisation

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAdmin => _userProfile?.isAdmin ?? false;
  bool get isInitialized => _isInitialized; // Getter pour l'état d'initialisation

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialiser l'authentification et écouter les changements
  void _initializeAuth() {
    AuthService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Gérer les changements d'état d'authentification
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    
    if (user != null) {
      await _loadUserProfile();
    } else {
      _userProfile = null;
    }
    
    // Marquer comme initialisé après le premier changement d'état
    if (!_isInitialized) {
      _isInitialized = true;
    }
    
    notifyListeners();
  }

  /// Charger le profil utilisateur depuis Firestore
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await AuthService.getCurrentUserProfile();
    } catch (e) {
      _setError('Erreur lors du chargement du profil: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _executeAuthOperation(() async {
      await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    });
  }

  /// Inscription avec email et mot de passe
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    bool isAdmin = false,
  }) async {
    return _executeAuthOperation(() async {
      await AuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        isAdmin: isAdmin,
      );
      return true;
    });
  }

  /// Déconnexion
  Future<bool> signOut() async {
    return _executeAuthOperation(() async {
      await AuthService.signOut();
      return true;
    });
  }

  /// Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    return _executeAuthOperation(() async {
      await AuthService.resetPassword(email);
      return true;
    });
  }

  /// Mettre à jour le profil utilisateur
  Future<bool> updateUserProfile(UserModel updatedProfile) async {
    return _executeAuthOperation(() async {
      await AuthService.updateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      return true;
    });
  }

  /// Rafraîchir le profil utilisateur
  Future<void> refreshUserProfile() async {
    if (!isAuthenticated) return;
    
    _setLoading(true);
    await _loadUserProfile();
    _setLoading(false);
  }

  /// Exécuter une opération d'authentification avec gestion d'état
  Future<bool> _executeAuthOperation(Future<bool> Function() operation) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await operation();
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Définir l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Définir un message d'erreur
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }


} 