# Projet : Magic Wand Battle - Cahier des Charges Complet

## 🎯 Objectif

Application mobile de duel de sorciers en 1 contre 1, dans laquelle les joueurs lancent des sorts à l'aide de mouvements détectés via les capteurs de leur téléphone (gyroscope/accéléromètre), synchronisés avec un compte à rebours. Une incantation vocale peut donner un bonus. L'administrateur gère les matchs, les scores et les arènes.

---

## 📱 État Actuel du Développement (Mis à jour)

### ✅ IMPLÉMENTÉ ET FONCTIONNEL

#### 🔐 Authentification
- **✅ Firebase Authentication** complètement configuré
- **✅ Login/Inscription** avec validation
- **✅ Gestion des rôles** admin/joueur
- **✅ Persistance de session** avec loading screen
- **✅ Déconnexion** avec redirection correcte

#### 🎨 Interface Utilisateur
- **✅ UI/UX moderne** complètement redesignée (suite retours utilisateur)
- **✅ Thème sombre** professionnel
- **✅ Navigation** fluide avec GoRouter
- **✅ Responsive design** adaptatif
- **✅ Animations** et transitions

#### 🔥 Firebase Backend
- **✅ Firestore Database** configuré (europe-west3)
- **✅ Storage** configuré (europe-west4)
- **✅ Règles de sécurité** granulaires
- **✅ Index composites** optimisés
- **✅ Collections** : users, spells, arenas, matches

#### 🎭 Gestion des Sorts
- **✅ Interface complète** création/édition/suppression
- **✅ Enregistrement des gestes** via capteurs
- **✅ Stockage Firebase** des données gestuelles
- **✅ Gestion en masse** (sélection multiple, suppression)
- **✅ Réparation chifoumi** automatique

#### 🎮 Mode Entraînement
- **✅ Interface simplifiée** : bouton → mouvement → détection
- **✅ Détection automatique** de sort sans sélection préalable
- **✅ Feedback visuel** et scores
- **✅ Mode "Tester autre sort"**

#### 📊 Dashboard Admin
- **✅ Statistiques temps réel** (utilisateurs, sorts, arènes)
- **✅ Accès gestion sorts**
- **✅ Interface debug** pour diagnostic
- **✅ Déploiement Firebase** automatisé

#### 📱 Compatibilité Mobile
- **✅ iOS 14.0+** support (résolu conflit Xcode 16.4)
- **✅ Android** compatible
- **✅ Capteurs** accéléromètre/gyroscope opérationnels
- **✅ Permissions** microphone/mouvement configurées

#### 🚀 Déploiement
- **✅ GitHub repository** configuré
- **✅ GitHub Actions** pour TestFlight iOS
- **✅ Configuration signing** iOS automatisée
- **✅ Export Options** pour App Store

### ⚠️ EN COURS DE RÉSOLUTION

#### 🔍 Reconnaissance Gestuelle
- **⚠️ Algorithme de base** fonctionnel mais peu fiable
- **⚠️ Comparaison** donne souvent 0% de similarité
- **⚠️ Service avancé** créé mais buggé (en pause)
- **⚠️ Seuils** trop stricts, ajustés à 20% pour debug
- **🔧 BESOIN** : Optimisation de l'algorithme de comparaison

#### 🎤 Reconnaissance Vocale
- **⚠️ Structure** prête mais pas implémentée
- **⚠️ Simulation** bonus avec Random() temporaire

### ❌ NON IMPLÉMENTÉ

#### 🏟️ Système d'Arènes
- **❌ Création d'arènes** (interface prête, logique manquante)
- **❌ Gestion matchs** temps réel
- **❌ Interface projection** Game Master

#### ⚔️ Système de Duel Réel
- **❌ Duel 1v1** temps réel entre joueurs
- **❌ Synchronisation** countdown
- **❌ Logique chifoumi** complète

#### 🏆 Système de Score
- **❌ Calcul points** (1 + 0.5 bonus vocal)
- **❌ Historique matchs** persistant
- **❌ Statistiques joueur** détaillées

---

## 🔧 Problèmes Techniques Identifiés

### 1. 🎯 Reconnaissance Gestuelle (EN COURS DE RÉSOLUTION)
**🎉 AVANCÉES MAJEURES (26 Jan 2025)** :
- ✅ **Erreur NaN/Infinity RÉSOLUE** - Fix division par zéro dans _resampleProfile()
- ✅ **Fréquence capteurs CORRIGÉE** - 5.2Hz → 85.5Hz (samplingPeriod=10ms)
- ✅ **Données optimisées** - 8 points → 108 points par geste (17x amélioration)
- ✅ **App stable** - Plus de crashes en mode release iOS
- ⚠️ **Reconnaissance fonctionnelle** - Scores > 0% mais précision à améliorer

**Problème résiduel** : Algorithme de comparaison encore imprécis sur gestes similaires
**Cause identifiée** : 
- Normalisation des trajectoires perfectible
- Pondération des critères à ajuster
- Seuils de reconnaissance à optimiser (actuellement 40%)

**Solutions appliquées** :
- ✅ **Fix critique** : Division par zéro dans rééchantillonnage
- ✅ **Haute fréquence iOS** : Capteurs forcés à 100Hz
- ✅ **Tests device réel** : Validation sur iPhone en mode release
- ✅ Filtre passe-bas  
- ✅ Seuils adaptatifs
- ✅ Pondération accéléromètre/gyroscope
- ❌ Service avancé avec features temporelles (buggé)

**Actions restantes (27 Jan 2025)** :
- **PRIORITÉ 1** : Affiner précision algorithme de comparaison
- Test systématique gestes distincts (ligne/cercle/zigzag)
- Ajustement seuils reconnaissance optimaux
- Amélioration normalisation trajectoires
- DTW (Dynamic Time Warping) si nécessaire

### 2. 📱 iOS Build (RÉSOLU)
**Problème** : Erreur `-G` avec Xcode 16.4 + Firebase BoringSSL-GRPC
**Solution** : Passage iOS 12.0 → iOS 14.0 + GitHub Actions avec Xcode 15

### 3. 🔄 Session Persistence (RÉSOLU)
**Problème** : Déconnexion à chaque refresh, logout sans redirection
**Solution** : Loading screen + Consumer<AuthProvider> + navigation explicite

### 4. 🎨 UI/UX (RÉSOLU)
**Problème** : Interface trop sombre, cards trop grandes, couleurs inadaptées
**Solution** : Redesign complet avec palette moderne et responsive

---

## 🎮 Fonctionnalités Prioritaires Restantes

### 🚨 CRITIQUE (Bloquant pour MVP)
1. **🔍 Correction reconnaissance gestuelle** - Algorithme fiable
2. **🎤 Reconnaissance vocale** - Bonus +0.5 réel
3. **⚔️ Duel 1v1 basique** - Sans temps réel, validation manuelle

### 🔥 IMPORTANT (MVP complet)
4. **🏟️ Création d'arènes** - Interface Game Master
5. **🏆 Système de score** - Calcul et persistance
6. **📊 Historique matchs** - Pour joueurs et admin

### 💡 NICE-TO-HAVE (Améliorations)
7. **🔄 Duel temps réel** - Synchronisation joueurs
8. **📺 Interface projection** - Pour spectateurs
9. **🏆 Tournois** - Gestion elimination

---

## 🛠️ Architecture Technique Actuelle

### Backend
- **Firebase/Firestore** : Base de données principale
- **Firebase Auth** : Authentification
- **Firebase Storage** : Assets (si nécessaire)
- **Règles Firestore** : Sécurité granulaire

### Frontend  
- **Flutter 3.32.7** : Framework mobile
- **Provider** : State management
- **GoRouter** : Navigation déclarative
- **sensors_plus** : Capteurs mouvement
- **speech_to_text** : Reconnaissance vocale (préparé)

### Services
- **AuthService** : Gestion authentification
- **SpellService** : CRUD sorts + chifoumi
- **GestureService** : Capture/comparaison gestes (à optimiser)
- **StatsService** : Statistiques temps réel
- **FirebaseDeploymentService** : Setup automatisé

### Modèles de Données
- **UserModel** : Profils utilisateur
- **SpellModel** : Sorts avec GestureData
- **ArenaModel** : Arènes de combat
- **MatchModel** : Matchs avec RoundModel
- **GestureData** : Données capteurs (AccelerometerReading, GyroscopeReading)

---

## 📋 Fonctionnalités détaillées

### Joueurs
- **✅ S'authentifient** dans l'application.
- **❌ Rejoignent un match** (arène 1v1) défini par l'admin.
- **✅ Ont accès à** :
  - **✅ L'interface de duel** (mode entraînement).
  - **❌ Leur profil, historique des matchs, statistiques**.

### Admin (Game Master)
- **❌ Crée des arènes** :
  - Type : match exhibition ou tournoi 1v1 en chaîne.
  - Paramètres : nombre de manches pour gagner, joueurs inscrits.
- **❌ Lance chaque manche** manuellement via une interface.
- **❌ Valide manuellement** le résultat de chaque manche.
- **❌ Dispose d'une interface de projection** (score, sort détecté, timer).
- **✅ Gère les sorts** : création, modification, suppression

### Moteur de jeu
- **⚠️ Détection des gestes** par gyroscope :
  - **✅ 6 sorts disponibles**.
  - **✅ Chaque sort = 1 pattern de mouvement**.
  - **✅ Les mouvements sont définis par l'admin** via enregistrement.
  - **⚠️ Reconnaissance peu fiable** (à corriger).
- **❌ Détection vocale** :
  - **✅ Chaque sort a une incantation** stockée.
  - **❌ Reconnaissance vocale** pas implémentée.
- **❌ Match** :
  - 1 point par manche gagnée.
  - +0.5 point de bonus si incantation correcte.
  - En cas d'égalité (même sort), la manche est relancée.
  - Le match s'arrête quand un joueur atteint le score cible.

### Interface utilisateur (joueur)
- **✅ Compte à rebours visible**.
- **❌ Indication "Trop tôt" ou "Trop tard"** si mouvement hors timing.
- **✅ Animation et vibration** en cas de réussite/échec.
- **⚠️ Visualisation du score** (basique), **❌ historique des manches**.

### Mode entraînement
- **✅ Permet à un joueur seul de s'entraîner** à effectuer les gestes.
- **✅ Feedbacks visuels** et scores.
- **❌ Feedbacks auditifs et vibratoires** (partiels).
- **✅ Interface simplifiée** : détection automatique sans sélection.

### Mode offline
- **❌ Non implémenté** - Tous les sorts sont stockés en ligne. 