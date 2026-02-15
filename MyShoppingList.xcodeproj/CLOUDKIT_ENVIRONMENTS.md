# ☁️ CloudKit : Environnements Development vs Production

## Vue d'ensemble

CloudKit utilise **deux environnements complètement séparés** :

1. **Development** : Pour le développement et les tests
2. **Production** : Pour TestFlight et l'App Store

⚠️ **Important** : Les données ne sont **JAMAIS** partagées entre les deux environnements.

---

## 🔧 Environnement Development

### Quand est-il utilisé ?
- Quand vous lancez l'app **depuis Xcode** en mode Debug
- Sur les appareils de développement connectés à Xcode
- Pendant les phases de développement et tests internes

### Caractéristiques
- ✅ Schéma modifiable librement
- ✅ Données de test séparées
- ✅ Suppression possible du schéma et des données
- ✅ Itération rapide
- ⚠️ Limité aux comptes développeurs ajoutés dans CloudKit Dashboard

### Accès aux Données
```
CloudKit Dashboard → Sélectionner "Development" → Data
```

### Configuration dans le Code
```swift
#if DEBUG
print("🔧 Mode DEBUG : Utilisation de l'environnement Development")
// Automatiquement utilisé quand BUILD_CONFIGURATION = Debug
#endif
```

---

## 🚀 Environnement Production

### Quand est-il utilisé ?
- ✅ TestFlight (builds distribués)
- ✅ App Store (version publique)
- ✅ Builds Release lancés depuis Xcode (si configuré)

### Caractéristiques
- ⚠️ Schéma **immuable** (peut seulement ajouter/modifier, pas supprimer)
- ✅ Données réelles des utilisateurs
- ✅ Accessible par tous les utilisateurs de l'app
- ⚠️ Déploiement du schéma **obligatoire** avant utilisation
- ⚠️ Impossible de supprimer le schéma une fois déployé

### Accès aux Données
```
CloudKit Dashboard → Sélectionner "Production" → Data
```

### Configuration dans le Code
```swift
#if DEBUG
// Development
#else
print("🚀 Mode RELEASE : Utilisation de l'environnement Production")
// Automatiquement utilisé quand BUILD_CONFIGURATION = Release
#endif
```

---

## 📊 Comparaison Détaillée

| Aspect | Development | Production |
|--------|-------------|------------|
| **Utilisation** | Debug depuis Xcode | TestFlight + App Store |
| **Schéma** | Modifiable librement | Déploiement unique, puis immuable |
| **Données** | Test, isolées | Réelles, permanentes |
| **Suppression** | Possible | Impossible |
| **Utilisateurs** | Comptes dev uniquement | Tous les utilisateurs |
| **Coût** | Gratuit (quotas dev) | Selon usage (gratuit jusqu'à un seuil) |
| **Reset** | Facile | ⚠️ Impossible |

---

## 🔄 Déployer le Schéma en Production

### Pourquoi est-ce nécessaire ?
Si vous ne déployez **PAS** le schéma en production :
- ❌ TestFlight : L'app crashera ou ne synchronisera pas
- ❌ App Store : Inutilisable avec CloudKit
- ❌ Partage : Impossible à créer

### Comment déployer ?

#### Étape 1 : Vérifier le Schéma Development
1. Aller sur https://icloud.developer.apple.com/dashboard/
2. Sélectionner votre conteneur : `iCloud.com.MyShoppingList`
3. Cliquer sur "Schema" dans le menu
4. En haut, sélectionner **"Development"**
5. Vérifier que vos types de records existent :
   ```
   ✅ CD_GroceryItemEntity
   ✅ CD_ShoppingListEntity
   ```

#### Étape 2 : Déployer
1. En haut à droite, cliquer sur **"Deploy to Production..."**
2. **Lire attentivement l'avertissement** :
   ```
   ⚠️ Une fois déployé :
   - Impossible de supprimer le schéma
   - Impossible de supprimer des types/champs
   - Seulement ajout/modification possible
   ```
3. Si vous êtes sûr, cliquer sur **"Deploy"**
4. Attendre quelques secondes (généralement < 1 minute)

#### Étape 3 : Vérifier le Déploiement
1. Changer l'environnement de "Development" à **"Production"** en haut
2. Cliquer sur "Schema"
3. Vérifier que les types sont présents :
   ```
   ✅ CD_GroceryItemEntity
   ✅ CD_ShoppingListEntity
   ```
4. Si oui → ✅ **Le déploiement est réussi !**

---

## 🧪 Tester les Deux Environnements

### Tester Development
```bash
# Dans Xcode
1. Product → Scheme → Edit Scheme
2. Run → Build Configuration : Debug
3. Product → Run (⌘R)
4. L'app utilise Development
```

### Tester Production (sans TestFlight)
```bash
# Dans Xcode
1. Product → Scheme → Edit Scheme
2. Run → Build Configuration : Release
3. Product → Run (⌘R)
4. L'app utilise Production
```

⚠️ **Note** : Tester en Release local peut parfois utiliser Development selon la configuration. TestFlight est le moyen le plus sûr.

---

## 🐛 Problèmes Courants

### "Bad Container" en Production
**Cause** : Le schéma n'est pas déployé en production

**Solution** :
1. Vérifier dans CloudKit Dashboard → Production → Schema
2. Si vide, déployer depuis Development

### Les données de Dev n'apparaissent pas en Prod
**C'est normal !** Les deux environnements sont complètement séparés.

**Solution** :
- Les utilisateurs TestFlight commenceront avec des données vides
- Chaque utilisateur créera sa propre liste

### Le partage ne fonctionne pas en TestFlight
**Cause** : Souvent lié au schéma non déployé ou permissions

**Solution** :
1. Vérifier le déploiement en Production
2. Vérifier que `databaseScope = .private` est configuré
3. Vérifier que les deux testeurs ont l'app installée

### Modifications du Schéma après Déploiement
**Scénario** : Vous ajoutez un nouveau champ à `GroceryItemEntity`

**Procédure** :
1. Modifier le modèle Core Data localement
2. Tester en Development
3. Redéployer le schéma (ajouter le nouveau champ)
   ```
   Dashboard → Development → Schema → Deploy to Production
   ```
4. CloudKit ajoute le champ en Production (migration automatique)
5. Les utilisateurs existants conservent leurs données + nouveau champ vide

---

## 📝 Checklist Avant Production

### Avant le Premier Déploiement
- [ ] Le schéma est complet et testé en Development
- [ ] Tous les champs nécessaires sont présents
- [ ] Les relations entre entités sont correctes
- [ ] Le partage fonctionne en Development
- [ ] ⚠️ Vous êtes **certain** du schéma (pas de retour en arrière possible)

### Déployer
- [ ] Accéder au CloudKit Dashboard
- [ ] Vérifier le schéma Development une dernière fois
- [ ] Cliquer sur "Deploy to Production"
- [ ] Confirmer le déploiement
- [ ] Vérifier dans Production que tout est présent

### Après le Déploiement
- [ ] Créer une archive Release
- [ ] Uploader sur TestFlight
- [ ] Tester sur appareil réel via TestFlight
- [ ] Vérifier que CloudKit fonctionne
- [ ] Vérifier que le partage fonctionne

---

## 🔐 Sécurité et Permissions

### Development
- Accessible uniquement par les comptes développeurs ajoutés
- Gérer dans : Dashboard → Team → Add/Remove Members

### Production
- Accessible par **tous les utilisateurs** de l'app
- Chaque utilisateur ne voit que ses propres données (+ celles partagées avec lui)
- Le partage respecte les permissions définies (lecture seule / lecture-écriture)

---

## 💡 Bonnes Pratiques

### 1. Tester Longuement en Development
- Ne déployez en Production qu'après des tests approfondis
- Simulez tous les scénarios d'utilisation
- Testez le partage entre plusieurs comptes

### 2. Documenter le Schéma
- Gardez une trace des versions du schéma
- Notez les champs ajoutés et quand
- Exemple :
  ```
  Version 1.0 (Initial) :
  - CD_GroceryItemEntity : id, name, isPurchased, frequency, dateAdded
  
  Version 1.1 :
  - Ajout : sharedZoneID (pour le partage)
  
  Version 1.2 :
  - Ajout : category (pour trier par catégorie)
  ```

### 3. Migrations
- CloudKit gère automatiquement les migrations
- Les nouveaux champs sont ajoutés avec valeurs par défaut
- Testez d'abord en Development avec des données réelles migrées

### 4. Plan B
- Même si le schéma est immuable, vous pouvez :
  - Ajouter de nouveaux types
  - Ajouter de nouveaux champs
  - Créer un nouveau conteneur (dernier recours)

---

## 🎯 Résumé en 3 Points

1. **Development** = Tests, modifications libres, données de dev
2. **Production** = TestFlight + App Store, schéma immuable, données réelles
3. **Déployer le schéma** = Étape **obligatoire** avant TestFlight

✅ **Une fois le schéma déployé et testé, vous êtes prêt pour production !**

---

## 📞 Ressources

- [Documentation Apple CloudKit](https://developer.apple.com/icloud/cloudkit/)
- [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
- [WWDC Sessions sur CloudKit](https://developer.apple.com/videos/cloudkit/)
