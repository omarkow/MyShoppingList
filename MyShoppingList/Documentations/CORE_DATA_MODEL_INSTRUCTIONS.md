# 📝 Instructions pour créer le modèle Core Data

## ⚠️ ACTION MANUELLE REQUISE

Vous devez créer un fichier `.xcdatamodeld` dans Xcode. Voici comment :

### 1️⃣ Créer le fichier de modèle

1. Dans Xcode, clic droit sur votre dossier projet
2. **New File** → **Data Model**
3. Nom : `MyShoppingList.xcdatamodeld`
4. Cliquez sur **Create**

### 2️⃣ Ajouter l'entité GroceryItemEntity

1. Ouvrez `MyShoppingList.xcdatamodeld`
2. Cliquez sur **Add Entity** en bas
3. Renommez-la en `GroceryItemEntity`
4. Dans la section **Class**, mettez : `GroceryItemEntity`
5. Dans **Module**, mettez : `MyShoppingList` (ou le nom de votre module)
6. Cochez **Codegen** : `Manual/None` (car on a créé la classe manuellement)

### 3️⃣ Ajouter les attributs

Cliquez sur `GroceryItemEntity` et ajoutez ces attributs :

| Nom | Type | Optional | Default |
|-----|------|----------|---------|
| `id` | UUID | ❌ No | - |
| `name` | String | ❌ No | "" |
| `isPurchased` | Boolean | ❌ No | NO |
| `frequency` | Integer 64 | ❌ No | 1 |
| `dateAdded` | Date | ❌ No | - |

### 4️⃣ Configurer CloudKit

1. Sélectionnez l'entité `GroceryItemEntity`
2. Dans l'inspecteur de droite (Data Model Inspector) :
   - ✅ Cochez **Used with CloudKit**
   
### 5️⃣ Configurer les contraintes (optionnel mais recommandé)

1. Sélectionnez l'entité `GroceryItemEntity`
2. En bas, section **Constraints** :
   - Ajoutez une contrainte sur `id` pour garantir l'unicité

---

## 🔄 Alternative : Si vous voulez que je génère le fichier XML

Core Data utilise un format XML en interne. Je peux créer le fichier `.xcdatamodel/contents` directement.

**Dites-moi si vous voulez que je génère ce fichier !**

---

## ✅ Après avoir créé le modèle

Une fois le `.xcdatamodeld` créé, vous pouvez :
1. Supprimer l'ancien fichier `GroceryItem.swift` (SwiftData)
2. Utiliser le nouveau `ContentView.swift` que je vais créer
3. Tester le partage CloudKit !
