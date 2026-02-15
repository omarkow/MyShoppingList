# Bug willSave() - Boucle Infinie Résolue

## 🐛 Symptôme

```
Thread 1: "Failed to process pending changes before save. 
The context is still dirty after 1000 attempts. 
Typically this recursive dirtying is caused by a bad validation method, 
-willSave, or notification handler."
```

## 🔍 Cause du Problème

### Code Original (Buggé)

```swift
public override func willSave() {
    super.willSave()
    if !isInserted && isUpdated {
        dateModified = Date()  // ❌ PROBLÈME ICI
    }
}
```

### Boucle Infinie Créée

```
1. L'utilisateur modifie un attribut (ex: name)
   └─> Core Data marque le contexte comme "dirty"
       └─> Core Data appelle willSave()
           └─> willSave() modifie dateModified
               └─> Core Data remarque un changement
                   └─> Core Data marque le contexte comme "dirty"
                       └─> Core Data appelle willSave()
                           └─> willSave() modifie dateModified
                               └─> Core Data remarque un changement
                                   └─> ♾️ BOUCLE INFINIE
```

## ✅ Solution

### Utiliser `setPrimitiveValue()`

```swift
public override func willSave() {
    super.willSave()
    
    if !isInserted && isUpdated {
        // Vérifier si dateModified est la seule chose qui a changé
        let changedKeys = changedValues().keys
        let hasRealChanges = changedKeys.contains(where: { $0 != "dateModified" })
        
        if hasRealChanges {
            // ✅ SOLUTION: Utiliser setPrimitiveValue
            setPrimitiveValue(Date(), forKey: "dateModified")
        }
    }
}
```

## 📚 Explication Technique

### Différence entre `property =` et `setPrimitiveValue()`

| Méthode | Comportement | Utilisation |
|---------|--------------|-------------|
| `dateModified = Date()` | Déclenche KVO + willChange/didChange | ❌ Dans willSave() → boucle |
| `setPrimitiveValue(Date(), forKey: "dateModified")` | Modifie directement sans notifications | ✅ Dans willSave() → OK |

### Flux avec la Solution

```
1. L'utilisateur modifie un attribut (ex: name)
   └─> Core Data marque le contexte comme "dirty"
       └─> Core Data appelle willSave()
           └─> willSave() utilise setPrimitiveValue()
               └─> dateModified est modifié SANS notifications
                   └─> Core Data continue la sauvegarde normalement
                       └─> ✅ Sauvegarde réussie !
```

## 🎯 Améliorations Supplémentaires

### Vérification des Vrais Changements

```swift
let changedKeys = changedValues().keys
let hasRealChanges = changedKeys.contains(where: { $0 != "dateModified" })

if hasRealChanges {
    setPrimitiveValue(Date(), forKey: "dateModified")
}
```

**Pourquoi ?**
- Évite de mettre à jour `dateModified` si c'est la seule chose qui a changé
- Évite les mises à jour inutiles dans CloudKit
- Meilleure performance

### Exemple Concret

```
Scénario 1: L'utilisateur change le nom de la liste
- changedKeys = ["name", "dateModified"]
- hasRealChanges = true
- ✅ On met à jour dateModified

Scénario 2: willSave() est appelé une 2ème fois (par Core Data)
- changedKeys = ["dateModified"]
- hasRealChanges = false
- ❌ On ne met PAS à jour dateModified
- → Pas de boucle infinie
```

## 🧪 Test de Validation

### Test Simple

```swift
let list = ShoppingListEntity.fetchOrCreateDefault(in: context)

// Modifier la liste
list.name = "Nouvelle Liste"

// Sauvegarder
try context.save()

// ✅ Devrait réussir sans erreur
// ✅ dateModified devrait être mis à jour
print("Date modifiée: \(list.dateModified)")
```

### Test Avancé

```swift
let list = ShoppingListEntity.fetchOrCreateDefault(in: context)

// Sauvegarder 100 fois
for i in 0..<100 {
    list.name = "Liste \(i)"
    try context.save()
}

// ✅ Devrait réussir 100 fois sans boucle infinie
print("100 sauvegardes réussies!")
```

## 📖 Ressources Apple

- [NSManagedObject Documentation](https://developer.apple.com/documentation/coredata/nsmanagedobject)
- [willSave() Method](https://developer.apple.com/documentation/coredata/nsmanagedobject/1506550-willsave)
- [setPrimitiveValue(_:forKey:)](https://developer.apple.com/documentation/coredata/nsmanagedobject/1506791-setprimitivevalue)

### Citation de la Documentation Apple

> **Important**
> 
> If you override `willSave()` to modify property values, you should typically use primitive accessor methods to avoid the possibility of generating  an infinite loop of change notifications.

Source: [NSManagedObject.willSave()](https://developer.apple.com/documentation/coredata/nsmanagedobject/1506550-willsave)

## 🎓 Leçons Apprises

### ❌ À NE PAS FAIRE

```swift
// ❌ Modifier un attribut avec l'accessor normal
dateModified = Date()

// ❌ Appeler save() dans willSave()
context.save()

// ❌ Modifier beaucoup d'attributs dans willSave()
name = "Test"
dateModified = Date()
```

### ✅ À FAIRE

```swift
// ✅ Utiliser setPrimitiveValue()
setPrimitiveValue(Date(), forKey: "dateModified")

// ✅ Faire le minimum de changements
// Seulement ce qui est vraiment nécessaire

// ✅ Vérifier si un vrai changement a eu lieu
if hasRealChanges {
    setPrimitiveValue(Date(), forKey: "dateModified")
}
```

## 🚀 Résultat

Avec cette correction :
- ✅ Pas de boucle infinie
- ✅ `dateModified` mis à jour automatiquement
- ✅ Performance optimale
- ✅ Compatible CloudKit
- ✅ Code propre et maintenable

---

**Bug résolu !** ✨
