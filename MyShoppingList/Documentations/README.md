# Ma Liste de Courses - Guide d'Utilisation

## 🛒 Vue d'Ensemble

Application de liste de courses collaborative avec synchronisation CloudKit en temps réel.

## ✨ Fonctionnalités

### 📝 Gestion de Liste
- ✅ Ajouter des articles
- ✅ Marquer comme acheté/non acheté
- ✅ Supprimer des articles
- ✅ Trier par nom ou fréquence d'achat
- ✅ Import CSV

### 🔄 Actions de Masse
- ✅ Tout marquer comme acheté
- ✅ Tout marquer comme non acheté  
- ✅ Supprimer tous les articles achetés

### 👥 Partage & Collaboration
- ✅ Partage CloudKit avec plusieurs utilisateurs
- ✅ Synchronisation en temps réel
- ✅ Permissions lecture/écriture
- ✅ Indicateur de synchronisation

### ☁️ iCloud
- ✅ Sauvegarde automatique
- ✅ Synchronisation entre appareils
- ✅ Historique des modifications

## 🎯 Comment Utiliser

### Ajouter un Article
1. Tapez le nom dans le champ en haut
2. Appuyez sur Entrée ou le bouton **+**
3. L'article apparaît dans "À acheter"

### Marquer comme Acheté
1. Appuyez sur l'article dans la liste
2. Il se déplace dans "Achetés" avec une opacité réduite

### Actions de Masse
1. Appuyez sur l'icône **✓** dans la barre supérieure
2. Choisissez une action :
   - Tout marquer comme acheté
   - Tout marquer comme non acheté
   - Supprimer les articles achetés

### Trier la Liste
1. Appuyez sur l'icône **↕️** dans la barre supérieure
2. Choisissez le tri :
   - Par nom (A-Z)
   - Par fréquence d'achat

### Partager avec d'Autres
1. Appuyez sur l'icône **👤+** dans la barre supérieure
2. Choisissez comment inviter (Message, Mail, etc.)
3. Les invités reçoivent un lien
4. Ils acceptent et peuvent modifier la liste en temps réel

Voir [PARTAGE_CLOUDKIT.md](PARTAGE_CLOUDKIT.md) pour plus de détails.

## 🔧 Configuration Requise

### Pour Utiliser l'App
- iOS 17.0 ou ultérieur
- Compte iCloud actif
- Connexion Internet (pour la synchronisation)

### Pour Développer
- Xcode 15.0+
- macOS Sonoma ou ultérieur
- Compte Apple Developer (pour CloudKit)

## 🏗️ Architecture Technique

### Technologies Utilisées
- **SwiftUI** : Interface utilisateur
- **Core Data** : Stockage local
- **CloudKit** : Synchronisation et partage
- **NSPersistentCloudKitContainer** : Intégration Core Data + CloudKit

### Fichiers Principaux

```
MyShoppingList/
├── MyShoppingListApp.swift       # Point d'entrée
├── ContentView.swift              # Interface principale
├── PersistenceController.swift    # Gestion Core Data + CloudKit
├── GroceryItemEntity.swift        # Modèle de données
└── SharingView.swift              # Interface de partage
```

### Modèle de Données

```swift
GroceryItemEntity
├── id: UUID?               // Identifiant unique
├── name: String            // Nom de l'article
├── isPurchased: Bool       // Acheté ou non
├── frequency: Int64        // Fréquence d'achat
└── dateAdded: Date?        // Date d'ajout
```

## 🧪 Développement

### Cloner et Lancer

```bash
git clone [votre-repo]
cd MyShoppingList
open MyShoppingList.xcodeproj
```

### Configuration CloudKit

1. Ouvrez le projet dans Xcode
2. Sélectionnez le target → Signing & Capabilities
3. Activez **iCloud**
4. Cochez **CloudKit**
5. Le container sera créé automatiquement : `iCloud.{votre-bundle-id}`

### Tester

#### Simulateur
- ✅ Fonctionnalités de base
- ✅ Interface utilisateur
- ❌ Partage CloudKit (nécessite plusieurs comptes iCloud)

#### Appareil Réel
- ✅ Toutes les fonctionnalités
- ✅ Synchronisation iCloud
- ✅ Partage avec d'autres utilisateurs

### Logs de Débogage

L'app affiche des logs détaillés dans la console :

```
📦 CloudKit Container: iCloud.com.exemple.MyShoppingList
✅ Core Data chargé
✅ PersistenceController initialisé avec succès
☁️ Événement CloudKit: Type: setup ✅ Succès
🔄 Changement distant détecté
```

## 🐛 Résolution de Problèmes

### L'app crash au démarrage

**Cause** : Store Core Data corrompu  
**Solution** : L'app supprime et recrée automatiquement le store

### Les données ne se synchronisent pas

1. Vérifiez que iCloud est activé : Réglages → iCloud
2. Vérifiez la connexion Internet
3. Relancez l'app
4. Regardez les logs pour voir les erreurs CloudKit

### Le partage ne fonctionne pas

Voir le guide détaillé : [PARTAGE_CLOUDKIT.md](PARTAGE_CLOUDKIT.md)

## 📚 Documentation Supplémentaire

- [Guide du Partage CloudKit](PARTAGE_CLOUDKIT.md) - Partage en temps réel
- [Apple CloudKit Documentation](https://developer.apple.com/documentation/cloudkit/)
- [Core Data + CloudKit](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)

## 🎨 Interface

### Écran Principal

```
┌─────────────────────────────┐
│  ↕️  ✓  📥      Ma Liste  🔄 👤+ │
├─────────────────────────────┤
│ [Ajouter un article...] [+] │
├─────────────────────────────┤
│ À acheter                    │
│ ○ Lait                       │
│ ○ Pain                       │
│ ○ Oeufs                      │
├─────────────────────────────┤
│ Achetés                      │
│ ● Fromage                    │
│ ● Beurre                     │
└─────────────────────────────┘
```

### Barre d'Outils

| Icône | Action |
|-------|--------|
| ↕️ | Trier la liste |
| ✓ | Actions de masse |
| 📥 | Importer CSV |
| 🔄 | Synchronisation (spinner) |
| 👤+ | Partager la liste |

## 🚀 Fonctionnalités Futures

- [ ] Catégories d'articles (Fruits, Légumes, etc.)
- [ ] Magasins favoris
- [ ] Historique des achats
- [ ] Suggestions intelligentes
- [ ] Mode hors ligne amélioré
- [ ] Widgets iOS
- [ ] Apple Watch companion

## 📄 Licence

Ce projet est un exemple éducatif. Utilisez-le librement pour apprendre ou comme base pour vos propres projets.

## 👨‍💻 Auteur

Développé comme exemple d'intégration Core Data + CloudKit + Partage en temps réel.

## 🙏 Remerciements

- Apple pour CloudKit et Core Data
- La communauté Swift pour les ressources et exemples
