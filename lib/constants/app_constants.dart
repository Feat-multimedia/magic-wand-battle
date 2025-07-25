class AppConstants {
  // Configuration Firebase
  static const String appName = 'Magic Wand Battle';
  static const String appVersion = '1.0.0';
  
  // Collections Firestore
  static const String usersCollection = 'users';
  static const String arenasCollection = 'arenas';
  static const String matchesCollection = 'matches';
  static const String roundsCollection = 'rounds';
  static const String spellsCollection = 'spells';
  
  // Paramètres du jeu
  static const int maxSpells = 6;
  static const double voiceBonusPoints = 0.5;
  static const int defaultRoundsToWin = 3;
  static const int gestureDetectionTimeoutMs = 5000;
  static const int countdownDurationSeconds = 3;
  
  // Seuils de détection
  static const double gestureThreshold = 2.0;
  static const double voiceConfidenceThreshold = 0.7;
  
  // Routes
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String arenaRoute = '/arena';
  static const String duelRoute = '/duel';
  static const String adminRoute = '/admin';
  static const String trainingRoute = '/training';
  
  // Couleurs du thème
  static const Map<String, String> themeColors = {
    'primary': '#6A0DAD',    // Violet magique
    'secondary': '#FF6B35',  // Orange mystique
    'accent': '#FFD700',     // Or brillant
    'background': '#1A1A2E', // Bleu très sombre
    'surface': '#16213E',    // Bleu nuit
    'error': '#FF4444',      // Rouge d'alerte
  };
} 