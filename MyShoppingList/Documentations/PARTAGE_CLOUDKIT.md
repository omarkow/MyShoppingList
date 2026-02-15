# Guide du Partage CloudKit en Temps Réel

## 🎯 Fonctionnalités Implémentées

### 1. Actions de Masse
- ✅ **Marquer tous comme acheté** : Coche tous les articles d'un coup
- ✅ **Marquer tous comme non acheté** : Réinitialise la liste
- ✅ **Supprimer les articles achetés** : Nettoie la liste après les courses

### 2. Partage CloudKit en Temps Réel
- ✅ **Partage de toute la liste** avec d'autres utilisateurs iCloud
- ✅ **Synchronisation automatique** des modifications
- ✅ **Permissions lecture/écriture** pour tous les participants

## 🚀 Comment Utiliser le Partage

### Étape 1 : Créer un Partage

1. Ajoutez des articles à votre liste
2. Appuyez sur le bouton **👤+** dans la barre supérieure
3. L'app va créer un partage CloudKit pour toute la liste
4. Une feuille de partage iOS apparaît

### Étape 2 : Inviter des Participants

Dans la feuille de partage :
1. Appuyez sur **"Ajouter des personnes"**
2. Choisissez comment inviter :
   - **Message** : Envoyer par iMessage
   - **Mail** : Envoyer par email
   - **Copier le lien** : Partager le lien d'une autre manière

### Étape 3 : Accepter une Invitation (Destinataire)

Quand quelqu'un reçoit votre invitation :
1. Il clique sur le lien reçu
2. iOS ouvre automatiquement l'app
3. La liste partagée apparaît dans son app
4. Toutes les modifications sont synchronisées en temps réel

## 🔄 Synchronisation en Temps Réel

### Comment ça fonctionne ?

- **Modifications instantanées** : Quand quelqu'un ajoute/modifie/supprime un article, tous les participants voient le changement immédiatement
- **Indicateur de synchronisation** : Un spinner apparaît dans la barre supérieure pendant la sync
- **CloudKit Container** : Toutes les données passent par iCloud de manière sécurisée

### Événements Synchronisés

✅ Ajout d'un article  
✅ Modification d'un article (nom, fréquence)  
✅ Cochage/décochage (acheté/non acheté)  
✅ Suppression d'un article  
✅ Actions de masse (tout cocher, tout décocher)

## 🔒 Sécurité et Permissions

### Permissions par Défaut

- **Propriétaire** : Peut tout faire + gérer les participants
- **Participants** : Peuvent lire et modifier tous les articles
- **Public** : Aucun accès (partage privé uniquement)

### Modifier les Permissions

Dans la feuille de partage :
1. Appuyez sur un participant
2. Choisissez les permissions :
   - **Lecture/Écriture** : Peut modifier
   - **Lecture seule** : Peut seulement voir
   - **Arrêter le partage** : Retirer l'accès

## 🛑 Arrêter le Partage

### Pour le Propriétaire

1. Ouvrez la feuille de partage (bouton 👤+)
2. Appuyez sur **"Arrêter le partage"**
3. Confirmez l'action
4. Tous les participants perdent l'accès
5. La liste redevient privée

### Pour un Participant

1. Ouvrez l'app Fichiers sur iOS
2. Allez dans **iCloud Drive**
3. Trouvez le partage et supprimez-le
4. Ou supprimez simplement l'app et réinstallez-la

## 🧪 Tester le Partage

### Avec un Seul Appareil (Simulateur)

⚠️ Limitation : Le simulateur ne peut pas tester le partage CloudKit car il faut plusieurs comptes iCloud différents.

### Avec Plusieurs Appareils (Recommandé)

1. **Appareil 1** (Propriétaire) :
   - Créez une liste avec quelques articles
   - Partagez-la avec un autre compte iCloud
   
2. **Appareil 2** (Participant) :
   - Acceptez l'invitation
   - Modifiez un article
   - Vérifiez que le changement apparaît sur l'appareil 1

3. **Test de synchronisation** :
   - Sur l'appareil 1 : Cochez un article
   - Sur l'appareil 2 : Vérifiez qu'il est coché (peut prendre quelques secondes)
   - Sur l'appareil 2 : Ajoutez un nouvel article
   - Sur l'appareil 1 : Vérifiez qu'il apparaît

## 📊 Indicateurs de Synchronisation

Dans l'app, vous verrez :

- **🔄 Changement distant détecté** : CloudKit a reçu une modification
- **☁️ Événement CloudKit** : Détails de la synchronisation
  - `setup` : Configuration initiale
  - `import` : Téléchargement depuis iCloud
  - `export` : Envoi vers iCloud
- **Spinner dans la barre** : Synchronisation en cours

## 🐛 Résolution de Problèmes

### Le partage ne fonctionne pas

1. **Vérifiez iCloud** :
   - Réglages → [Votre nom] → iCloud
   - Assurez-vous que iCloud Drive est activé
   - Vérifiez que l'app a l'autorisation d'utiliser iCloud

2. **Vérifiez la connexion** :
   - L'appareil doit être connecté à Internet
   - CloudKit ne fonctionne pas hors ligne

3. **Vérifiez les Capabilities** (Dans Xcode) :
   - Target → Signing & Capabilities
   - **iCloud** doit être activé
   - **CloudKit** doit être coché

### Les modifications ne se synchronisent pas

1. **Attendez quelques secondes** : La synchronisation peut prendre 5-10 secondes
2. **Forcez la synchronisation** : Fermez et rouvrez l'app
3. **Vérifiez les logs** : Regardez la console Xcode pour les erreurs CloudKit

### Erreur "Zone not found"

- Cette erreur peut apparaître si le partage a été supprimé manuellement
- Solution : Arrêtez le partage et recréez-en un nouveau

## 💡 Bonnes Pratiques

1. **Ne partagez pas avec trop de personnes** : CloudKit limite à environ 100 participants par partage
2. **Testez sur de vrais appareils** : Le simulateur a des limitations avec iCloud
3. **Gardez l'app à jour** : Les participants doivent avoir la même version de l'app
4. **Gérez les permissions** : Retirez l'accès aux anciens participants

## 🎉 Cas d'Usage

### Liste de Courses en Famille
- Le parent crée la liste
- Tous les membres de la famille peuvent ajouter des articles
- Pendant les courses, on coche en temps réel

### Colocation
- Un colocataire crée la liste des courses communes
- Tout le monde peut voir ce qui manque
- Évite d'acheter en double

### Événements
- Organiser un pique-nique, barbecue, etc.
- Chacun ajoute ce qu'il peut apporter
- Liste à jour pour tout le monde

## 📝 Notes Techniques

### Architecture CloudKit

```
Propriétaire                    Participants
     |                               |
     |    Crée le partage            |
     |----------------------------->|
     |                               |
     |    Accepte l'invitation       |
     |<-----------------------------|
     |                               |
     |  Synchronisation continue     |
     |<=============================>|
     |         via iCloud            |
```

### Structure des Données

- **Zone privée** : Données personnelles (avant partage)
- **Zone partagée** : Données accessibles aux participants (après partage)
- **Records CloudKit** : Chaque article = 1 record CKRecord

### Limitations CloudKit

- **Taille** : 1 MB par record (largement suffisant pour un article)
- **Requêtes** : 400 requêtes/seconde
- **Stockage** : 10 GB gratuits par app, puis payant
- **Participants** : ~100 par partage
