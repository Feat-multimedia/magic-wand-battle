# Projet : Magic Wand Battle - Cahier des Charges Complet

## Objectif

Application mobile de duel de sorciers en 1 contre 1, dans laquelle les joueurs lancent des sorts à l'aide de mouvements détectés via les capteurs de leur téléphone (gyroscope/accéléromètre), synchronisés avec un compte à rebours. Une incantation vocale peut donner un bonus. L'administrateur gère les matchs, les scores et les arènes.

---

## Fonctionnalités principales

### Joueurs
- S'authentifient dans l'application.
- Rejoignent un match (arène 1v1) défini par l'admin.
- Ont accès à :
  - L'interface de duel.
  - Leur profil, historique des matchs, statistiques.

### Admin (Game Master)
- Crée des arènes :
  - Type : match exhibition ou tournoi 1v1 en chaîne.
  - Paramètres : nombre de manches pour gagner, joueurs inscrits.
- Lance chaque manche manuellement via une interface.
- Valide manuellement le résultat de chaque manche (en cas de doute ou de problème réseau).
- Dispose d'une interface de projection (score, sort détecté, timer).

### Moteur de jeu
- Détection des gestes par gyroscope :
  - 6 sorts disponibles.
  - Chaque sort = 1 pattern de mouvement.
  - Les mouvements sont définis par l'admin en amont dans l'interface d'administration via un enregistrement (capture du mouvement).
- Détection vocale :
  - Chaque sort a une incantation facultative.
  - Si la reconnaissance du mot est correcte (avec marge d'erreur), un bonus est appliqué.
- Match :
  - 1 point par manche gagnée.
  - +0.5 point de bonus si incantation correcte.
  - En cas d'égalité (même sort), la manche est relancée.
  - Le match s'arrête quand un joueur atteint le score cible.

### Interface utilisateur (joueur)
- Compte à rebours visible.
- Indication "Trop tôt" ou "Trop tard" si le mouvement est hors du timing.
- Animation et vibration en cas de réussite/échec.
- Visualisation du score, de l'historique des manches et des sorts utilisés.

### Mode entraînement
- Permet à un joueur seul de s'entraîner à effectuer les gestes et incantations.
- Pas de points, mais feedbacks visuels, auditifs et vibratoires.

### Mode offline
- Matchs peuvent être mis en pause.
- Résultats stockés et conservés.

---

## Structure base de données (Firestore)

### users
- `id: string`
- `displayName: string`
- `email: string`
- `isAdmin: bool`
- `stats: object` (matchs joués, points, sorts utilisés, taux de réussite)
- `createdAt: timestamp`

### arenas
- `id: string`
- `title: string`
- `type: enum` (`exhibition`, `tournament`)
- `status: enum` (`waiting`, `in_progress`, `finished`)
- `createdBy: DocumentReference(users)`
- `maxRounds: int`
- `players: array of DocumentReference(users)`
- `createdAt: timestamp`

### matches
- `id: string`
- `arenaId: DocumentReference(arenas)`
- `player1: DocumentReference(users)`
- `player2: DocumentReference(users)`
- `winner: DocumentReference(users) | null`
- `status: enum` (`pending`, `in_progress`, `finished`)
- `roundsToWin: int`
- `createdAt: timestamp`

#### matches/{matchId}/rounds
- `id: string`
- `index: int`
- `player1Spell: string`
- `player2Spell: string`
- `player1Voice: string | null`
- `player2Voice: string | null`
- `player1Bonus: float`
- `player2Bonus: float`
- `winner: DocumentReference(users) | null`
- `timestamp: timestamp`

### spells
- `id: string`
- `name: string`
- `gestureData: object` (accéléromètre/gyroscope pattern)
- `voiceKeyword: string`
- `beats: string` (id d'un autre sort battu)
- `createdAt: timestamp`

---

## Logique de jeu

- L'admin définit 6 sorts via enregistrement de mouvement.
- Chaque sort est lié à un ou plusieurs autres sorts via un système en boucle (chifoumi étendu).
  Exemple : Sort A bat Sort B, B bat C, C bat D, D bat E, E bat F, F bat A.
- Chaque sort a une incantation vocale facultative.
- Le moteur de jeu détecte :
  - Si le mouvement correspond à un sort défini (via reconnaissance de pattern).
  - Si la voix correspond au mot du sort (avec seuil de tolérance).
  - Si le timing est correct (post signal).
- Si les 2 joueurs ont lancé un sort valide dans le bon timing, l'app détermine le vainqueur de la manche.
- Sinon, un feedback est donné (trop tôt, non reconnu, etc.) et la manche peut être relancée ou perdue.

---

## Interfaces à prévoir

### Joueur
- Auth / Dashboard / Match en cours / Historique
- Écran duel avec :
  - Countdown.
  - Caméra activée (facultatif pour voix).
  - Feedback en temps réel (sort détecté, animation, vibration).
  - Résultat de la manche.

### Admin
- Dashboard général
- Création / édition d'arènes
- Lancement manuel de manche
- Vue des matchs en cours (live)
- Interface de projection avec :
  - Timer.
  - Sorts des joueurs.
  - Score.
  - Résultats.

---

## Contraintes

- Aucune mécanique de monétisation à intégrer.
- Tous les sorts sont accessibles à tous les joueurs.
- L'app doit fonctionner sans effet secondaire entre les sorts.
- Le système de reconnaissance vocale et gestuelle doit être extensible mais cohérent.
- L'ordre de domination des sorts est circulaire (dernier bat le premier).
- L'historique des matchs doit être visible par l'admin et le joueur.
- Tous les résultats sont validés manuellement par l'admin (bouton "valider manche").

---

## Extensions futures (non prioritaires)

- Ajout de badges
- Classement Elo
- Tournois automatiques à bracket
- Historique public
- Matchs amicaux en ligne (sans admin)

---

## Notes de développement

- La détection de mouvement peut être faite avec les capteurs gyroscope/accéléromètre via [sensors_plus](https://pub.dev/packages/sensors_plus).
- La reconnaissance vocale peut être gérée via [speech_to_text](https://pub.dev/packages/speech_to_text).
- L'enregistrement d'un nouveau sort consiste à :
  - Capturer les données de mouvement de l'admin (mobile).
  - Définir le mot associé.
  - Sauvegarder dans la collection `spells`.

---

## État d'avancement du projet

### ✅ Phase 1 - Base (TERMINÉ)
- [x] Modèles de données Firestore (User, Arena, Match, Round, Spell)
- [x] Structure application (routing GoRouter, thème, navigation)
- [x] Écrans de base (Login, Home, Profile, Admin)
- [x] Configuration Firebase de base

### ✅ Phase 2 - Authentification (TERMINÉ)
- [x] Service d'authentification Firebase complet
- [x] Provider de gestion d'état utilisateur
- [x] Intégration dans les écrans (login, inscription, déconnexion)
- [x] Gestion des rôles admin/joueur

### 🔄 Phase 3 - Services Core (À FAIRE)
- [ ] Services Firestore CRUD (users, arenas, matches, spells)
- [ ] Service de détection des mouvements (capteurs)
- [ ] Service de reconnaissance vocale
- [ ] Moteur de jeu principal

### 🔄 Phase 4 - Interfaces de jeu (À FAIRE)
- [ ] Interface création/gestion des sorts (admin)
- [ ] Interface création d'arènes
- [ ] Interface de duel avec countdown
- [ ] Mode entraînement
- [ ] Interface de projection

### 🔄 Phase 5 - Finition (À FAIRE)
- [ ] Mode offline
- [ ] Synchronisation temps réel
- [ ] Animations et effets
- [ ] Tests et optimisation

---

## Architecture technique

### Frontend Flutter
- **State Management**: Provider
- **Routing**: GoRouter
- **UI**: Material Design 3 avec thème custom
- **Capteurs**: sensors_plus (gyroscope/accéléromètre)
- **Voix**: speech_to_text
- **Animations**: Lottie, vibrations

### Backend Firebase
- **Authentification**: Firebase Auth
- **Base de données**: Cloud Firestore
- **Temps réel**: Firestore listeners
- **Sécurité**: Rules Firestore

### Logique métier
- **Système chifoumi circulaire**: A > B > C > D > E > F > A
- **Scoring**: 1pt base + 0.5pt bonus vocal
- **Validation**: Manuelle par l'admin
- **Timing**: Synchronisé via timestamp Firestore 