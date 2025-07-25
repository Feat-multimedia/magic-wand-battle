# 👑 Configuration du Premier Administrateur

## 🚨 Sécurité : Pourquoi pas d'inscription admin directe ?

Par sécurité, **aucun utilisateur ne peut s'inscrire directement en tant qu'administrateur** via l'application. Cela évite que n'importe qui puisse obtenir des privilèges admin.

## 🎯 Méthodes pour créer le premier admin

### Méthode 1 : Via Firebase Console (Recommandée)

1. **Créer un compte utilisateur normal** dans l'app
2. **Aller dans Firebase Console** → [https://console.firebase.google.com/](https://console.firebase.google.com/)
3. **Sélectionner votre projet** `magic-wand-battle`
4. **Aller dans Firestore Database**
5. **Trouver la collection `users`**
6. **Localiser votre document utilisateur** (par email)
7. **Modifier le champ `isAdmin`** : changer `false` → `true`
8. **Sauvegarder**

✅ **Résultat** : Votre compte devient admin instantanément !

### Méthode 2 : Via code de déploiement (Développement)

Si vous développez l'app, vous pouvez modifier temporairement le service de déploiement pour créer un admin :

```dart
// Dans lib/services/firebase_deployment_service.dart
// Méthode _createTestData() - ligne ~320

// Ajouter temporairement :
final adminUser = UserModel(
  id: '',
  displayName: 'VOTRE_NOM',
  email: 'VOTRE_EMAIL@example.com', // Même email que votre compte
  isAdmin: true, // ← Important !
  stats: UserStats(/* ... */),
  createdAt: DateTime.now(),
);

await _firestore
    .collection(AppConstants.usersCollection)
    .add(adminUser.toFirestore());
```

⚠️ **N'oubliez pas de supprimer ce code après** !

## 🔄 Promouvoir d'autres utilisateurs en admin

Une fois que vous êtes admin, vous pouvez promouvoir d'autres utilisateurs :

### Via l'interface admin (À implémenter)

1. **Se connecter en tant qu'admin**
2. **Aller dans Administration**
3. **Section "Gestion des utilisateurs"** (à créer)
4. **Sélectionner un utilisateur**
5. **Cocher "Administrateur"**
6. **Sauvegarder**

### Via Firebase Console (Actuel)

1. **Firestore Database** → Collection `users`
2. **Trouver l'utilisateur à promouvoir**
3. **Modifier `isAdmin: false` → `true`**

## 🛡️ Bonnes pratiques de sécurité

### ✅ À faire :
- **Limiter le nombre d'admins** (2-3 maximum)
- **Utiliser des emails professionnels** pour les admins
- **Documenter qui est admin** et pourquoi
- **Révoquer les droits admin** quand nécessaire

### ❌ À éviter :
- Donner les droits admin "au cas où"
- Utiliser des comptes personnels pour admin
- Laisser des comptes admin inactifs
- Partager les identifiants admin

## 🔍 Vérifier le statut admin

### Dans l'application :
- **Menu utilisateur** montre "(Admin)" à côté du nom
- **Bouton "Administration"** visible dans le menu principal
- **Accès aux fonctionnalités** de création d'arènes, sorts, etc.

### Dans Firebase Console :
- **Collection `users`** → Votre document → Champ `isAdmin: true`

## 🚨 En cas de problème

### J'ai perdu mes droits admin :
1. Vérifier dans Firebase Console
2. Modifier `isAdmin` → `true`
3. Redémarrer l'app

### Aucun admin disponible :
1. Créer un nouveau compte utilisateur
2. Le promouvoir via Firebase Console
3. Se connecter avec ce compte

### Erreurs de permissions :
1. Vérifier les règles Firestore sont déployées
2. Confirmer que `isAdmin: true` dans Firestore
3. Redémarrer l'application complètement

---

## 📋 Checklist premier admin

- [ ] Compte utilisateur créé dans l'app
- [ ] Champ `isAdmin` modifié dans Firebase Console
- [ ] Déconnexion/reconnexion dans l'app
- [ ] Vérification des droits (bouton Administration visible)
- [ ] Test de création d'arène ou sort
- [ ] Documentation du compte admin créé 