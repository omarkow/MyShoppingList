# 🔀 Comparaison : SwiftData vs Core Data pour le partage CloudKit

## 🎯 Objectif : Partager une liste de courses entre utilisateurs

---

## 📊 Tableau comparatif

| Critère | SwiftData | Core Data |
|---------|-----------|-----------|
| **Syntaxe** | ✨ Moderne, Swift pur | 📜 Objective-C legacy |
| **Complexité** | 🟢 Simple | 🟡 Moyenne |
| **Partage CloudKit** | 🔴 Non supporté | 🟢 Natif |
| **UICloudSharingController** | ❌ | ✅ |
| **Collaboration temps réel** | ❌ | ✅ |
| **Sync CloudKit** | ✅ | ✅ |
| **Migrations automatiques** | ✅ | ⚠️ Manuelles |
| **Documentation** | 🟡 Récente | 🟢 Abondante |
| **Maturité** | 🆕 iOS 17+ | 🏛️ Depuis iOS 3 |

---

## 💻 Exemples de code

### 1. Définition d'un modèle

#### SwiftData
```swift
@Model
class GroceryItem {
    var id: UUID = UUID()
    var name: String = ""
    var isPurchased: Bool = false
    var frequency: Int = 1
}
```
✅ **Simple et clair**

#### Core Data
```swift
@objc(GroceryItemEntity)
public class GroceryItemEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var isPurchased: Bool
    @NSManaged public var frequency: Int64
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        // ...
    }
}
```
⚠️ **Plus verbeux, nécessite `@NSManaged`**

---

### 2. Récupération des données

#### SwiftData
```swift
@Query private var items: [GroceryItem]

// Tri
@Query(sort: \GroceryItem.name) 
private var sortedItems: [GroceryItem]
```
✅ **Déclaratif et élégant**

#### Core Data
```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \GroceryItemEntity.name, ascending: true)],
    animation: .default
)
private var items: FetchedResults<GroceryItemEntity>
```
⚠️ **Plus technique, utilise `NSSortDescriptor`**

---

### 3. Ajout d'un item

#### SwiftData
```swift
let item = GroceryItem(name: "Lait")
modelContext.insert(item)
```
✅ **Simple et intuitif**

#### Core Data
```swift
let item = GroceryItemEntity(context: viewContext)
item.id = UUID()
item.name = "Lait"
try? viewContext.save()
```
⚠️ **Doit initialiser manuellement et sauvegarder**

---

### 4. Synchronisation CloudKit

#### SwiftData
```swift
let config = ModelConfiguration(
    "MyApp",
    schema: schema,
    cloudKitDatabase: .private("iCloud.com.MyApp")
)
```
✅ **Configuration simple**
❌ **Mais AUCUN partage possible**

#### Core Data
```swift
let container = NSPersistentCloudKitContainer(name: "MyApp")
container.persistentStoreDescriptions.first?.cloudKitContainerOptions = 
    NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.MyApp")
```
✅ **Sync ET partage complets**

---

### 5. **PARTAGE CLOUDKIT** ⭐

#### SwiftData
```swift
// ❌ IMPOSSIBLE
// SwiftData ne supporte pas UICloudSharingController
// Solution alternative : Export CSV + ShareSheet
```

#### Core Data
```swift
// ✅ POSSIBLE
let (_, share, _) = try await container.share([item], to: nil)

// Afficher UICloudSharingController
let controller = UICloudSharingController(
    preparationHandler: { handler in
        handler(share, container, nil)
    }
)
present(controller, animated: true)
```

---

## 🎯 Cas d'usage recommandés

### Utilisez **SwiftData** si :
- ✅ Vous démarrez un nouveau projet
- ✅ Vous n'avez PAS besoin de partage CloudKit
- ✅ Vous voulez du code moderne et simple
- ✅ Vous ciblez iOS 17+

**Exemple :** App personnelle, journal intime, notes privées

---

### Utilisez **Core Data** si :
- ✅ Vous avez besoin de **partage CloudKit**
- ✅ Vous voulez la **collaboration multi-utilisateurs**
- ✅ Vous devez supporter iOS < 17
- ✅ Vous avez déjà un projet Core Data existant

**Exemple :** Liste de courses partagée, projet d'équipe, app collaborative

---

## 📈 Matrice de décision

```
Besoin de partage CloudKit ?
        │
        ├─ OUI ──────────────► Core Data (obligatoire)
        │
        └─ NON
            │
            ├─ iOS 17+ seulement ? ──► SwiftData (recommandé)
            │
            └─ Support iOS 15/16 ? ──► Core Data
```

---

## 🔄 Migration SwiftData → Core Data

### Effort requis : 🟡 Moyen

**Étapes :**
1. Créer le modèle `.xcdatamodeld`
2. Réécrire les entités avec `NSManagedObject`
3. Remplacer `@Query` par `@FetchRequest`
4. Adapter le contexte (`modelContext` → `viewContext`)
5. Tester la migration des données

**Temps estimé :** 2-4 heures pour une petite app

---

## 💰 Coût/Bénéfice pour votre projet

### Votre besoin : **Partager une liste de courses**

| Critère | SwiftData | Core Data | Gagnant |
|---------|-----------|-----------|---------|
| Simplicité du code | 🟢 | 🟡 | SwiftData |
| Partage entre utilisateurs | 🔴 | 🟢 | **Core Data** |
| Temps de dev | 🟢 | 🟡 | SwiftData |
| Fonctionnalité complète | 🔴 | 🟢 | **Core Data** |

**Verdict : Core Data est le seul choix viable pour votre cas.**

---

## 🔮 Futur de SwiftData

Apple pourrait ajouter le support du partage CloudKit dans SwiftData, mais :
- ❌ Aucune annonce officielle
- ❌ Pas dans iOS 18 (février 2026)
- ❌ Pas de roadmap publique

**Recommandation :** N'attendez pas, utilisez Core Data maintenant.

---

## 📚 Ressources

### SwiftData
- [Documentation Apple](https://developer.apple.com/documentation/swiftdata)
- WWDC 2023: "Meet SwiftData"

### Core Data + CloudKit Sharing
- [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [CKShare Documentation](https://developer.apple.com/documentation/cloudkit/ckshare)
- WWDC 2021: "Sync a Core Data store with CloudKit"

---

## ✅ Conclusion pour votre projet

**Pour une liste de courses PARTAGÉE entre utilisateurs :**

→ **Core Data est obligatoire**

SwiftData est excellent pour le développement moderne, mais ne répond pas (encore) à votre besoin de collaboration.

La migration que j'ai implémentée vous donne :
- ✅ Partage natif via `UICloudSharingController`
- ✅ Invitations par Messages/Mail
- ✅ Synchronisation bidirectionnelle en temps réel
- ✅ Gestion automatique des permissions
- ✅ Indicateur de sync dans l'UI

**C'est la seule solution viable actuellement.** 🎯
