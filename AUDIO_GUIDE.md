# 🎵 Guide d'Ajout de Sons - Magic Wand Battle

## 📂 **Structure des fichiers requis**

Pour que l'app utilise tes sons, place-les exactement à ces emplacements :

### ⚡ **Sons de Sorts** (`assets/sounds/spells/`)
```
assets/sounds/spells/
├── fireball.mp3      → Sort de feu 🔥
├── ice_blast.mp3     → Sort de glace ❄️
├── lightning.mp3     → Sort de foudre ⚡
├── heal.mp3          → Sort de soin 💚
├── shield.mp3        → Sort de bouclier 🛡️
└── meteor.mp3        → Sort de météore ☄️
```

### 🎯 **Effets Sonores** (`assets/sounds/effects/`)
```
assets/sounds/effects/
├── spell_success.mp3  → Son de réussite ✅
├── spell_fail.mp3     → Son d'échec ❌
├── victory.mp3        → Son de victoire 🏆
├── defeat.mp3         → Son de défaite 😔
├── spell_cast.mp3     → Sort générique 🎯
├── duel_start.mp3     → Début de duel 🚀
└── countdown.mp3      → Compte à rebours ⏰
```

### 🖱️ **Sons d'Interface** (`assets/sounds/ui/`)
```
assets/sounds/ui/
├── button_click.mp3   → Clic de bouton 🔘
├── notification.mp3   → Notification 📢
└── whoosh.mp3         → Transition fluide ✨
```

### 🎼 **Musique** (`assets/sounds/music/`)
```
assets/sounds/music/
└── battle_theme.mp3   → Musique de fond des duels 🎵
```

## 🛠️ **Comment procéder**

### **Méthode 1 : Drag & Drop** (Plus simple)
1. Ouvre le dossier `assets/sounds/spells/` dans le Finder
2. Glisse-dépose ton fichier audio dedans
3. Renomme-le exactement comme requis (ex: `fireball.mp3`)
4. Relance l'app → **Le son sera automatiquement utilisé !**

### **Méthode 2 : Terminal** 
```bash
# Exemple: ajouter un son de feu
cp /chemin/vers/ton/son.mp3 assets/sounds/spells/fireball.mp3

# Vérifier que c'est bien là
ls assets/sounds/spells/
```

## 🎨 **Recommandations Audio**

### **Format & Qualité**
- **Format** : MP3 (compatible partout)
- **Qualité** : 128kbps (bon compromis taille/qualité)
- **Durée** : 
  - Sons de sorts : 1-3 secondes
  - Effets : 0.5-2 secondes  
  - Interface : 0.2-1 seconde
  - Musique : 2-5 minutes (boucle parfaite)

### **Volume**
- **Normalize** tes sons (même niveau sonore)
- **Pas de saturation** (éviter les craquements)
- **Fade in/out** léger pour les transitions

## 🎵 **Où trouver des sons ?**

### **🆓 Sources Gratuites**
- **Freesound.org** → Sons libres haute qualité
- **Zapsplat.com** → Effets sonores (gratuit avec compte)
- **Adobe Audition** → Bibliothèque intégrée
- **YouTube Audio Library** → Effets + musiques libres

### **🔍 Mots-clés de recherche**
- **Feu** : "fire spell", "fireball", "flame whoosh"
- **Glace** : "ice spell", "freeze", "crystal magic"  
- **Foudre** : "thunder spell", "lightning zap", "electric"
- **Interface** : "ui click", "button press", "notification"
- **Victoire** : "victory fanfare", "win sound", "success"

### **🎼 Musique Épique**
- **Recherche** : "fantasy battle music", "epic orchestral loop"
- **Style** : Médiéval fantastique, orchestral, mystique
- **Éviter** : Paroles, tempo trop rapide

## ⚡ **Test Immédiat**

Après avoir ajouté tes sons :

1. **Ouvre l'app**
2. **Va dans "Paramètres Audio"**  
3. **Teste chaque bouton** → Tes nouveaux sons jouent !
4. **Lance un duel** → Expérience complète !

## 🔄 **Fallback Intelligent**

Si un fichier manque, l'app utilise automatiquement :
- **Vibrations** + tonalités système
- **Pas de crash** → Toujours fonctionnel
- **Logs explicites** pour débugger

## 📱 **Exemple Complet**

```bash
# Créer un son de feu basique (macOS)
say -v "Alex" -o temp.aiff "Fire spell cast"
ffmpeg -i temp.aiff assets/sounds/spells/fireball.mp3
rm temp.aiff

# L'app utilise maintenant ce son pour tous les sorts de feu !
```

---

## 🚀 **Résultat Final**

Avec tes propres sons :
- ✅ **Expérience unique** et personnalisée
- ✅ **Immersion totale** dans les duels
- ✅ **Professionnalisme** audio complet
- ✅ **Tests intégrés** pour valider

**Commence par 2-3 sons pour tester, puis complète selon tes préférences !** 