# 🚀 QUICKSTART - Migration Core Data

## ⚡ Démarrage rapide (5 étapes)

### 1️⃣ Exécuter le script (Terminal)
```bash
cd /chemin/vers/votre/projet
bash setup_coredata.sh
```

### 2️⃣ Dans Xcode - Ajouter le modèle
1. File → Add Files to "MyShoppingList"
2. Sélectionnez `MyShoppingList.xcdatamodeld`
3. Cliquez Add

### 3️⃣ Vérifier les Capabilities
Project → Signing & Capabilities :
- [x] iCloud
- [x] CloudKit
- [x] Container: `iCloud.com.MyShoppingList`

### 4️⃣ Build & Run
```
⌘ + R
```

### 5️⃣ Tester le partage
1. Ajoutez des items
2. Appuyez sur le bouton partage (👤➕)
3. Partagez via Messages
4. Acceptez sur un autre appareil

---

## 📁 Nouveaux fichiers ajoutés

```
MyShoppingList/
├── GroceryItemEntity.swift          ← Modèle Core Data
├── PersistenceController.swift      ← Gestion CloudKit
├── ContentView.swift                ← UI mise à jour
├── MyShoppingListApp.swift          ← App mise à jour
├── SharingView.swift                ← UICloudSharingController
├── MyShoppingList.xcdatamodeld/     ← Modèle de données
│   └── MyShoppingList.xcdatamodel/
│       └── contents
└── setup_coredata.sh                ← Script de setup
```

---

## 🎯 Différences principales

### AVANT (SwiftData)
```swift
@Query private var items: [GroceryItem]
modelContext.insert(item)
```
❌ Pas de partage CloudKit

### APRÈS (Core Data)
```swift
@FetchRequest private var items: FetchedResults<GroceryItemEntity>
viewContext.insert(item)
```
✅ Partage CloudKit complet

---

## 🐛 Problèmes courants

| Erreur | Solution |
|--------|----------|
| "Could not load model" | Ajoutez `.xcdatamodeld` au projet |
| "CloudKit not enabled" | Activez iCloud dans Capabilities |
| Rien ne se partage | Vérifiez la connexion iCloud |

---

## 📞 Aide

Lisez les guides détaillés :
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Instructions complètes
- [README_CORE_DATA.md](README_CORE_DATA.md) - Vue d'ensemble
- [SWIFTDATA_VS_COREDATA.md](SWIFTDATA_VS_COREDATA.md) - Comparaison

---

**C'est parti ! 🎉**
