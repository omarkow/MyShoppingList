# 🚀 Guide Rapide : Déployer sur TestFlight

## ⏱️ Résumé en 5 Minutes

Vous avez terminé le développement et le partage fonctionne ? Voici les étapes essentielles pour TestFlight.

---

## ✅ Étape 1 : CloudKit Dashboard (5 min)

### Déployer le Schéma en Production

1. **Aller sur** : https://icloud.developer.apple.com/dashboard/
2. **Sélectionner** : `iCloud.com.MyShoppingList`
3. **Cliquer** : "Schema" → Environnement "Development"
4. **Vérifier** : `CD_GroceryItemEntity` et `CD_ShoppingListEntity` existent
5. **Déployer** : Bouton "Deploy to Production..." en haut à droite
6. **Confirmer** : Lire l'avertissement et confirmer
7. **Vérifier** : Changer en "Production" et voir que le schéma est là

✅ **C'est l'étape la plus critique !** Sans cela, TestFlight ne fonctionnera pas.

---

## ✅ Étape 2 : Configuration Xcode (2 min)

### Vérifier le Scheme

1. **Ouvrir** : Product → Scheme → Edit Scheme (⌘<)
2. **Sélectionner** : "Archive" dans la colonne de gauche
3. **Vérifier** : Build Configuration = **Release** (pas Debug)
4. **Fermer**

### Vérifier la Version

1. **Target** → General → Identity
2. **Version** : 1.0 (ou votre numéro de version)
3. **Build** : 1 (incrémenter à chaque upload : 2, 3, 4...)

---

## ✅ Étape 3 : Créer l'Archive (5 min)

1. **Sélectionner** : "Any iOS Device (arm64)" comme destination
2. **Clean** : Product → Clean Build Folder (⇧⌘K)
3. **Archive** : Product → Archive
4. **Attendre** : La compilation prend quelques minutes
5. **Organizer** : S'ouvre automatiquement avec votre archive

---

## ✅ Étape 4 : Upload vers App Store Connect (5 min)

1. **Dans Organizer** : Sélectionner votre archive
2. **Distribute App** : Cliquer sur le bouton
3. **Choisir** : "TestFlight & App Store"
4. **Suivre** : Les étapes (Upload, Signing, Confirmer)
5. **Attendre** : Upload en cours (peut prendre 5-10 min selon la connexion)

---

## ✅ Étape 5 : App Store Connect (30 min d'attente)

1. **Aller sur** : https://appstoreconnect.apple.com
2. **My Apps** → Sélectionner votre app
3. **TestFlight** : Onglet en haut
4. **Attendre** : "Processing" → Devient disponible (10-30 min)
5. **Ajouter testeurs** : Internal Testing → Ajouter des testeurs
6. **Distribuer** : Sélectionner le build et distribuer

---

## ✅ Étape 6 : Tester ! (10 min)

### Sur Votre iPhone

1. **Télécharger** : TestFlight depuis l'App Store
2. **Se connecter** : Avec votre Apple ID
3. **Installer** : MyShoppingList
4. **Lancer** : L'app
5. **Vérifier** :
   - ✅ L'app se lance
   - ✅ Ajouter des articles fonctionne
   - ✅ La synchronisation iCloud fonctionne
   - ✅ Le bouton de partage s'ouvre correctement

### Avec un Deuxième Testeur (Partage)

1. **Créer un partage** sur votre appareil
2. **Envoyer le lien** via Messages
3. **L'autre testeur** ouvre le lien et accepte
4. **Vérifier** : Les deux voient la même liste
5. **Modifier** : Ajouter des articles des deux côtés
6. **Confirmer** : La synchronisation fonctionne

---

## ⚠️ Problèmes Fréquents

### "Bad Container" ou Erreur CloudKit
→ Le schéma n'est pas déployé en Production (retour à l'Étape 1)

### L'upload échoue
→ Vérifier que le Build Number est unique et jamais utilisé

### Le partage ne fonctionne pas
→ Vérifier que les deux testeurs ont l'app installée et iCloud actif

### Processing prend trop de temps (> 1h)
→ Patience ! Parfois ça peut prendre jusqu'à 2h. Si > 24h, contacter Apple.

---

## 📚 Documentation Complète

Pour plus de détails, consultez :

- **`DEPLOYMENT_CHECKLIST.md`** : Checklist complète étape par étape
- **`CLOUDKIT_ENVIRONMENTS.md`** : Comprendre Development vs Production
- **`TESTING_SHARING.md`** : Guide complet pour tester le partage

---

## 🎉 Vous Êtes Prêt !

Si toutes ces étapes sont complétées :

✅ Le schéma CloudKit est en Production  
✅ L'archive est uploadée sur App Store Connect  
✅ Les testeurs peuvent installer via TestFlight  
✅ La synchronisation fonctionne  
✅ Le partage fonctionne  

🚀 **Votre app est prête pour le déploiement App Store !**

---

## 🔄 Pour les Prochaines Versions

1. Modifier votre code
2. Incrémenter le **Build Number** (ex: 2, 3, 4...)
3. Product → Archive
4. Upload vers TestFlight
5. Les testeurs reçoivent automatiquement la mise à jour

⚠️ Si vous modifiez le modèle Core Data, pensez à **redéployer le schéma** CloudKit !
