# 🤝 Guide de Test du Partage CloudKit

## Vue d'ensemble

Le partage CloudKit permet à plusieurs utilisateurs de collaborer sur la même liste de courses en temps réel. Voici comment tester cette fonctionnalité.

---

## 📋 Prérequis

### Matériel Nécessaire
- **2 appareils iOS physiques** (iPhone ou iPad)
  - ⚠️ Le simulateur ne supporte **PAS** le partage CloudKit
- Les deux appareils doivent avoir :
  - iOS 16.0 minimum (ou la version minimale de votre app)
  - Une connexion Internet active
  - Un compte iCloud actif et connecté

### Comptes iCloud
- **2 comptes Apple ID différents**
- Les deux comptes doivent être connectés à iCloud sur leurs appareils respectifs

---

## 🧪 Scénario de Test Complet

### Étape 1 : Préparation (Appareil A - Propriétaire)

1. **Installer l'app** depuis TestFlight
2. **Ouvrir l'app** et se connecter à iCloud si demandé
3. **Ajouter plusieurs articles** :
   ```
   - Pommes
   - Pain
   - Lait
   - Œufs
   ```
4. **Marquer quelques articles** comme achetés (pour tester la synchronisation)
5. **Attendre quelques secondes** pour la synchronisation CloudKit initiale

### Étape 2 : Créer le Partage (Appareil A)

1. **Appuyer sur l'icône de partage** (👤+ en haut à droite)
2. **Vérifier** :
   - ✅ Un spinner apparaît brièvement
   - ✅ L'interface de partage UICloudSharingController s'ouvre
   - ✅ Le titre est "Ma Liste de Courses"
   - ✅ Vous voyez les options de partage

3. **Configurer le partage** :
   - Permissions : **Peut modifier** (lecture/écriture)
   - Accès : **Personnes invitées uniquement** (privé)

4. **Partager le lien** :
   - Appuyer sur "Ajouter des personnes"
   - Choisir un moyen de partage :
     - **Messages** (recommandé pour les tests)
     - Mail
     - AirDrop
     - Copier le lien

5. **Envoyer au testeur** sur l'Appareil B

### Étape 3 : Accepter l'Invitation (Appareil B - Participant)

1. **Installer l'app** depuis TestFlight
2. **Ouvrir le lien reçu** :
   - Via Messages : Appuyer sur le lien
   - Via Mail : Appuyer sur le lien
   - Lien copié : Ouvrir dans Safari puis appuyer sur "Ouvrir dans MyShoppingList"

3. **Accepter l'invitation** :
   - Un message système apparaît
   - Appuyer sur "Rejoindre" ou "Open"
   - L'app s'ouvre automatiquement

4. **Vérifier la liste partagée** :
   - ✅ Vous voyez les articles ajoutés par l'Appareil A
   - ✅ Les articles achetés ont la bonne coche
   - ✅ Le nombre d'articles correspond

### Étape 4 : Tests de Synchronisation Bidirectionnelle

#### Test A → B (Propriétaire vers Participant)

**Sur Appareil A** :
1. Ajouter un nouvel article : `Tomates`
2. Marquer `Pain` comme acheté

**Sur Appareil B** :
- ✅ Attendre 5-10 secondes
- ✅ `Tomates` devrait apparaître automatiquement
- ✅ `Pain` devrait être coché

#### Test B → A (Participant vers Propriétaire)

**Sur Appareil B** :
1. Ajouter un nouvel article : `Fromage`
2. Décocher `Lait` (le remettre comme non acheté)

**Sur Appareil A** :
- ✅ Attendre 5-10 secondes
- ✅ `Fromage` devrait apparaître
- ✅ `Lait` devrait être décoché

#### Test Simultané

**Simultanément** :
- Sur Appareil A : Ajouter `Beurre`
- Sur Appareil B : Ajouter `Confiture`

**Résultat attendu** (après quelques secondes) :
- ✅ Les deux appareils montrent `Beurre` ET `Confiture`
- ✅ Pas de perte de données
- ✅ Pas de conflit visible

### Étape 5 : Tests de Modification

**Modifier un article existant** :

**Sur Appareil A** :
- Appuyer sur `Pommes`
- Changer le nom en `Pommes Vertes`

**Sur Appareil B** :
- ✅ Après quelques secondes, devrait afficher `Pommes Vertes`

### Étape 6 : Tests de Suppression

**Sur Appareil B** :
- Glisser vers la gauche sur `Œufs`
- Appuyer sur "Supprimer"

**Sur Appareil A** :
- ✅ `Œufs` devrait disparaître après quelques secondes

### Étape 7 : Test de Tri et Fréquence

**Sur Appareil A** :
1. Appuyer sur l'icône de tri (↕️)
2. Choisir "Fréquence d'achat"
3. Marquer plusieurs fois `Pain` comme acheté/non acheté

**Sur Appareil B** :
- ✅ Le tri devrait s'appliquer
- ✅ `Pain` devrait remonter dans la liste (haute fréquence)

### Étape 8 : Test des Opérations en Masse

**Sur Appareil A** :
1. Appuyer sur l'icône checklist (✓)
2. Choisir "Tout marquer comme acheté"

**Sur Appareil B** :
- ✅ Tous les articles devraient être cochés après quelques secondes

**Sur Appareil B** :
1. Appuyer sur l'icône checklist
2. Choisir "Supprimer les articles achetés"

**Sur Appareil A** :
- ✅ Les articles achetés devraient disparaître

---

## 🔍 Tests Avancés

### Test de Perte de Connexion

**Sur Appareil B** :
1. Activer le mode Avion
2. Ajouter `Chocolat`
3. Marquer `Fromage` comme acheté

**Résultat** :
- ✅ Les modifications sont sauvegardées localement
- ⚠️ Pas d'erreur visible

**Sur Appareil B** :
4. Désactiver le mode Avion
5. Attendre la reconnexion

**Sur Appareil A** :
- ✅ Après quelques secondes, `Chocolat` apparaît
- ✅ `Fromage` est coché

### Test d'Arrêt du Partage

**Sur Appareil A (propriétaire uniquement)** :
1. Appuyer sur l'icône de partage
2. Appuyer sur "Gérer les participants" ou "Arrêter le partage"
3. Confirmer l'arrêt

**Sur Appareil B** :
- ⚠️ La liste peut devenir vide ou inaccessible
- ✅ Aucun crash ne devrait se produire

---

## ⏱️ Temps de Synchronisation

### Temps Normaux
- **Ajout d'article** : 2-10 secondes
- **Modification** : 2-10 secondes
- **Suppression** : 2-10 secondes
- **Reconnexion après hors-ligne** : 5-30 secondes

### Si la Synchronisation est Lente
- ✅ Vérifier la connexion Internet
- ✅ Fermer et rouvrir l'app
- ✅ Vérifier dans Réglages → iCloud que la synchronisation est active
- ✅ Attendre jusqu'à 1 minute dans certains cas

---

## ✅ Checklist de Validation Finale

### Fonctionnalités de Base
- [ ] Créer un partage
- [ ] Envoyer un lien de partage
- [ ] Accepter une invitation
- [ ] Voir les données partagées

### Synchronisation
- [ ] Ajout A → B
- [ ] Ajout B → A
- [ ] Modification A → B
- [ ] Modification B → A
- [ ] Suppression A → B
- [ ] Suppression B → A

### Edge Cases
- [ ] Modifications simultanées (pas de conflit)
- [ ] Mode hors-ligne puis reconnexion
- [ ] Ajout massif d'articles (10+)
- [ ] Tri synchronisé
- [ ] Fréquence synchronisée

### Expérience Utilisateur
- [ ] Pas de crash
- [ ] Interface fluide
- [ ] Pas de clignotement excessif
- [ ] Messages d'erreur clairs (si applicable)
- [ ] Indicateurs de chargement visibles

---

## 🐛 Problèmes Connus et Solutions

### Le lien de partage ne s'ouvre pas
- ✅ Vérifier que les deux appareils ont l'app installée
- ✅ Vérifier que les deux appareils sont connectés à iCloud
- ✅ Réessayer d'envoyer le lien

### Les modifications ne se synchronisent pas
- ✅ Vérifier la connexion Internet
- ✅ Fermer et rouvrir l'app sur les deux appareils
- ✅ Vérifier dans les logs (si accessible) les erreurs CloudKit

### "Bad Container" ou erreurs CloudKit
- ⚠️ Le schéma n'est probablement pas déployé en Production
- ✅ Retourner au CloudKit Dashboard et déployer

### Les articles apparaissent en double
- ⚠️ Possible conflit de synchronisation rare
- ✅ Supprimer les doublons
- ✅ Signaler le bug si reproductible

---

## 📊 Rapport de Test

Une fois tous les tests effectués, remplir ce rapport :

```
# Rapport de Test du Partage - MyShoppingList
Date : _____________________
Version : ___________________

## Appareils Testés
Appareil A : iPhone/iPad _______ - iOS _____
Appareil B : iPhone/iPad _______ - iOS _____

## Résultats
✅ Création du partage
✅ Envoi du lien
✅ Acceptation de l'invitation
✅ Synchronisation A → B
✅ Synchronisation B → A
✅ Modifications simultanées
✅ Mode hors-ligne

## Problèmes Rencontrés
[Décrire tout problème]

## Notes
[Observations supplémentaires]

## Conclusion
□ Prêt pour production
□ Nécessite des corrections
```

---

## 🎯 Critères de Succès

Pour considérer le partage CloudKit comme **fonctionnel et prêt pour production** :

1. ✅ Le partage se crée sans erreur
2. ✅ Le lien peut être partagé via Messages/Mail
3. ✅ L'invitation est acceptée correctement
4. ✅ La synchronisation fonctionne dans les deux sens
5. ✅ Le délai de synchronisation est < 15 secondes en moyenne
6. ✅ Aucun crash n'est observé
7. ✅ Les modifications hors-ligne se synchronisent après reconnexion
8. ✅ L'expérience utilisateur est fluide et intuitive

Si **tous ces critères sont remplis**, votre app est prête pour TestFlight et production ! 🎉
