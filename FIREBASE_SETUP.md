# 🔥 Configuration Firebase - Magic Wand Battle

## 📋 Étapes de création du projet Firebase

### 1. Créer le projet Firebase
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquer sur "Ajouter un projet"
3. Nom du projet : `magic-wand-battle`
4. Activer Google Analytics (optionnel)
5. Choisir le compte Analytics (si activé)

### 2. Configurer Authentication
1. Dans Firebase Console → Authentication
2. Onglet "Sign-in method"
3. Activer "Email/Password"
4. Optionnel : Activer "Google" pour connexion simplifiée

### 3. Configurer Firestore Database
1. Dans Firebase Console → Firestore Database
2. Créer une base de données
3. **Mode test pour commencer** (on configurera les règles après)
4. Choisir la région : `europe-west1` (Europe)

### 4. Ajouter l'app Flutter
1. Dans Firebase Console → Project Settings
2. Ajouter une app → Flutter
3. Suivre les instructions FlutterFire CLI

---

## 🔧 Configuration automatique avec FlutterFire CLI

### Installation FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### Configuration du projet
```bash
# Dans le répertoire du projet
flutterfire configure

# Choisir le projet créé : magic-wand-battle
# Sélectionner les plateformes : android, ios, web
# Les fichiers de config seront générés automatiquement
```

---

## 📁 Structure des collections Firestore

### Collection `users`
```
users/{userId}
├── displayName: string
├── email: string
├── isAdmin: boolean
├── stats: map
│   ├── matchsPlayed: number
│   ├── totalPoints: number
│   ├── spellsUsed: map
│   └── successRate: number
└── createdAt: timestamp
```

### Collection `spells`
```
spells/{spellId}
├── name: string
├── gestureData: map
│   ├── accelerometerReadings: array
│   ├── gyroscopeReadings: array
│   ├── threshold: number
│   └── duration: number
├── voiceKeyword: string
├── beats: string (référence spellId)
└── createdAt: timestamp
```

### Collection `arenas`
```
arenas/{arenaId}
├── title: string
├── type: string (exhibition|tournament)
├── status: string (waiting|in_progress|finished)
├── createdBy: reference (/users/{userId})
├── maxRounds: number
├── players: array[reference]
└── createdAt: timestamp
```

### Collection `matches`
```
matches/{matchId}
├── arenaId: reference (/arenas/{arenaId})
├── player1: reference (/users/{userId})
├── player2: reference (/users/{userId})
├── winner: reference (/users/{userId}) | null
├── status: string (pending|in_progress|finished)
├── roundsToWin: number
├── createdAt: timestamp
└── rounds: subcollection
    └── rounds/{roundId}
        ├── index: number
        ├── player1Spell: string
        ├── player2Spell: string
        ├── player1Voice: string | null
        ├── player2Voice: string | null
        ├── player1Bonus: number
        ├── player2Bonus: number
        ├── winner: reference | null
        └── timestamp: timestamp
```

---

## 🔒 Règles de sécurité Firestore

### Règles complètes (firestore.rules)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fonction helper pour vérifier si l'utilisateur est authentifié
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Fonction helper pour vérifier si l'utilisateur est admin
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Fonction helper pour vérifier si c'est le propriétaire du document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Collection users
    match /users/{userId} {
      // Lecture : utilisateur connecté peut lire son profil ou admin peut tout lire
      allow read: if isOwner(userId) || isAdmin();
      
      // Création : seulement lors de l'inscription (par l'utilisateur lui-même)
      allow create: if isOwner(userId) && 
                    request.resource.data.email == request.auth.token.email;
      
      // Mise à jour : utilisateur peut modifier son profil, admin peut tout modifier
      allow update: if isOwner(userId) || isAdmin();
      
      // Suppression : seulement admin
      allow delete: if isAdmin();
    }
    
    // Collection spells
    match /spells/{spellId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isAuthenticated();
      
      // Écriture : seulement admin
      allow write: if isAdmin();
    }
    
    // Collection arenas
    match /arenas/{arenaId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isAuthenticated();
      
      // Création : seulement admin
      allow create: if isAdmin();
      
      // Mise à jour : seulement admin ou créateur de l'arène
      allow update: if isAdmin() || 
                    (isAuthenticated() && 
                     resource.data.createdBy == /databases/$(database)/documents/users/$(request.auth.uid));
      
      // Suppression : seulement admin
      allow delete: if isAdmin();
    }
    
    // Collection matches
    match /matches/{matchId} {
      // Lecture : joueurs du match ou admin
      allow read: if isAdmin() || 
                  (isAuthenticated() && 
                   (resource.data.player1 == /databases/$(database)/documents/users/$(request.auth.uid) ||
                    resource.data.player2 == /databases/$(database)/documents/users/$(request.auth.uid)));
      
      // Écriture : seulement admin
      allow write: if isAdmin();
      
      // Sous-collection rounds
      match /rounds/{roundId} {
        // Lecture : joueurs du match parent ou admin
        allow read: if isAdmin() || 
                    (isAuthenticated() && 
                     (get(/databases/$(database)/documents/matches/$(matchId)).data.player1 == /databases/$(database)/documents/users/$(request.auth.uid) ||
                      get(/databases/$(database)/documents/matches/$(matchId)).data.player2 == /databases/$(database)/documents/users/$(request.auth.uid)));
        
        // Écriture : seulement admin
        allow write: if isAdmin();
      }
    }
  }
}
```

---

## 📊 Index Firestore requis

### Index composites nécessaires
```javascript
// Collection: arenas
// Champs: status (Ascending), createdAt (Descending)

// Collection: matches  
// Champs: status (Ascending), createdAt (Descending)

// Collection: matches
// Champs: player1 (Ascending), status (Ascending), createdAt (Descending)

// Collection: matches
// Champs: player2 (Ascending), status (Ascending), createdAt (Descending)

// Collection: rounds (sous-collection de matches)
// Champs: timestamp (Descending)
```

---

## 🚀 Configuration de déploiement automatique

### firebase.json
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### firestore.indexes.json
```json
{
  "indexes": [
    {
      "collectionGroup": "arenas",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "matches",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "matches",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "player1",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "rounds",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        {
          "fieldPath": "timestamp",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## ⚙️ Scripts de déploiement

### deploy.sh
```bash
#!/bin/bash
echo "🔥 Déploiement Firebase Magic Wand Battle"

# Construire l'app web
echo "📱 Construction de l'app web..."
flutter build web

# Déployer les règles et index Firestore
echo "🔒 Déploiement des règles Firestore..."
firebase deploy --only firestore:rules

echo "📊 Déploiement des index Firestore..."
firebase deploy --only firestore:indexes

# Déployer l'hosting web (optionnel)
# echo "🌐 Déploiement web hosting..."
# firebase deploy --only hosting

echo "✅ Déploiement terminé !"
```

---

## 🎯 Données initiales à créer

### Premier admin (à créer manuellement)
```javascript
// Document: users/[uid-admin]
{
  displayName: "Game Master",
  email: "admin@magicwand.com",
  isAdmin: true,
  stats: {
    matchsPlayed: 0,
    totalPoints: 0,
    spellsUsed: {},
    successRate: 0
  },
  createdAt: [timestamp]
}
```

### Sorts par défaut (6 sorts du système chifoumi)
```javascript
// À créer via l'interface admin une fois l'app déployée
// 1. Fireball > Ice Shield
// 2. Ice Shield > Lightning Bolt  
// 3. Lightning Bolt > Earth Quake
// 4. Earth Quake > Wind Blade
// 5. Wind Blade > Shadow Strike
// 6. Shadow Strike > Fireball
``` 