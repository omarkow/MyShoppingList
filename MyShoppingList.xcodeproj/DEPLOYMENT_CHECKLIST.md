# 📋 Checklist de Déploiement TestFlight - MyShoppingList

## ✅ Configuration Xcode

### 1. Bundle Identifier & Signing
- [ ] Target → General → Identity → Bundle Identifier est correct
- [ ] Target → Signing & Capabilities → Team est sélectionné
- [ ] "Automatically manage signing" est coché (ou certificats configurés manuellement)

### 2. Capabilities iCloud
- [ ] Target → Signing & Capabilities → "+ Capability" → iCloud (si pas déjà ajouté)
- [ ] ☑️ CloudKit
- [ ] ☑️ Container `iCloud.com.MyShoppingList` est coché
  - **IMPORTANT** : Si le conteneur n'existe pas, créez-le avec le bouton "+"
  - Le nom doit être **exactement** `iCloud.com.MyShoppingList` ou ajustez le code dans `PersistenceController.swift`

### 3. Version & Build
- [ ] Target → General → Version : Définir la version (ex: 1.0)
- [ ] Target → General → Build : Incrémenter à chaque upload TestFlight (ex: 1, 2, 3...)

### 4. Scheme Configuration
- [ ] Product → Scheme → Edit Scheme (⌘<)
- [ ] Sélectionner "Archive" dans la liste de gauche
- [ ] Build Configuration : **Release** (PAS Debug)
- [ ] Fermer

---

## ☁️ Configuration CloudKit Dashboard

### 1. Accéder au Dashboard
- [ ] Aller sur https://icloud.developer.apple.com/dashboard/
- [ ] Se connecter avec compte Apple Developer

### 2. Vérifier le Schéma en Development
- [ ] Sélectionner le conteneur `iCloud.com.MyShoppingList`
- [ ] Cliquer sur "Schema" dans le menu
- [ ] Environnement : **Development**
- [ ] Vérifier que ces types existent :
  - [ ] `CD_GroceryItemEntity` avec les champs : id, name, isPurchased, frequency, dateAdded, sharedZoneID
  - [ ] `CD_ShoppingListEntity` avec les champs : id, name, dateCreated, dateModified, isShared
  - [ ] Relation entre les deux entités

### 3. ⚠️ DÉPLOYER EN PRODUCTION (CRITIQUE!)
- [ ] Cliquer sur "Deploy to Production..." en haut à droite
- [ ] **LIRE L'AVERTISSEMENT** : Impossible de supprimer un schéma une fois déployé
- [ ] Confirmer le déploiement
- [ ] Attendre quelques secondes

### 4. Vérifier la Production
- [ ] Changer l'environnement de "Development" à "Production"
- [ ] Vérifier que `CD_GroceryItemEntity` et `CD_ShoppingListEntity` sont présents
- [ ] ✅ Si oui, le déploiement est réussi !

---

## 📱 Tests avant Archive

### 1. Tests sur Appareil Physique
- [ ] L'app se lance sans crash
- [ ] Ajouter des articles → ✅ fonctionne
- [ ] Marquer comme acheté → ✅ fonctionne
- [ ] Synchronisation CloudKit → ✅ vérifier dans iCloud
- [ ] Partage CloudKit → ✅ interface s'affiche (ne pas forcément envoyer)

### 2. Tests en Mode Release Local
- [ ] Product → Scheme → Edit Scheme → Run → Build Configuration : Release
- [ ] Lancer l'app (⌘R)
- [ ] Vérifier qu'il n'y a pas d'erreur spécifique au mode Release
- [ ] Remettre en "Debug" après les tests

---

## 🚀 Archive & Upload TestFlight

### 1. Créer l'Archive
- [ ] Product → Clean Build Folder (⇧⌘K)
- [ ] Sélectionner "Any iOS Device (arm64)" comme destination
- [ ] Product → Archive
- [ ] Attendre la fin de la compilation (peut prendre quelques minutes)

### 2. Upload vers App Store Connect
- [ ] La fenêtre Organizer s'ouvre automatiquement
- [ ] Sélectionner votre archive
- [ ] Cliquer sur "Distribute App"
- [ ] Choisir "TestFlight & App Store"
- [ ] Suivre les étapes :
  - Upload
  - Signing automatique (ou manuel)
  - Confirmer

### 3. Attendre le Processing
- [ ] Aller sur https://appstoreconnect.apple.com
- [ ] My Apps → MyShoppingList → TestFlight
- [ ] Attendre que "Processing" devienne disponible (10-30 min généralement)

---

## 🧪 Tests TestFlight

### 1. Ajouter des Testeurs Internes
- [ ] App Store Connect → TestFlight → Internal Testing
- [ ] Ajouter votre groupe de testeurs
- [ ] Distribuer le build

### 2. Tests Critiques à Effectuer
- [ ] Installer depuis TestFlight
- [ ] Se connecter à iCloud
- [ ] Ajouter des articles
- [ ] Vérifier la synchronisation
- [ ] **Tester le partage** :
  - [ ] Créer un partage
  - [ ] Envoyer le lien à un autre testeur
  - [ ] Vérifier que l'autre personne voit la liste
  - [ ] Modifier des articles des deux côtés
  - [ ] Vérifier la synchronisation bidirectionnelle

---

## ⚠️ Problèmes Courants

### "Bad Container" / CloudKit ne fonctionne pas
- ✅ Vérifier que le conteneur `iCloud.com.MyShoppingList` existe dans Capabilities
- ✅ Vérifier que le schéma est déployé en Production
- ✅ Redémarrer Xcode
- ✅ Clean Build Folder (⇧⌘K)

### Upload échoue
- ✅ Vérifier que le Build Number est unique (jamais utilisé)
- ✅ Vérifier que le certificat de distribution est valide
- ✅ Vérifier que l'App ID existe sur developer.apple.com

### Le partage ne fonctionne pas en TestFlight
- ✅ Vérifier que le schéma CloudKit est déployé en **Production**
- ✅ Les deux testeurs doivent avoir la même version
- ✅ Les deux testeurs doivent être connectés à iCloud
- ✅ Attendre quelques secondes après la création du lien

---

## 📝 Notes Importantes

1. **Development vs Production CloudKit** :
   - En Debug depuis Xcode → Development
   - TestFlight & App Store → Production
   - Les données ne sont **PAS** partagées entre les deux environnements

2. **Première fois** :
   - Le déploiement du schéma en production est **obligatoire**
   - Cela ne peut être fait qu'une seule fois
   - Impossible de supprimer après (seulement ajouter/modifier)

3. **Versions futures** :
   - Si vous modifiez le modèle Core Data, redéployez le schéma
   - CloudKit migre automatiquement les données existantes

4. **Partage CloudKit** :
   - Fonctionne uniquement entre utilisateurs ayant l'app installée
   - Nécessite iOS 16+ (selon votre déploiement cible)
   - Les testeurs TestFlight peuvent partager entre eux

---

## ✅ Quand tout est fait

- [ ] L'app est sur TestFlight
- [ ] Les testeurs peuvent installer
- [ ] La synchronisation CloudKit fonctionne
- [ ] Le partage fonctionne
- [ ] Pas de crash majeur

🎉 **Vous êtes prêt pour le déploiement App Store !**
