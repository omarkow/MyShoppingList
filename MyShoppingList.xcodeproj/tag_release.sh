#!/bin/bash

# Script de Tag Git pour Release
# Usage: ./tag_release.sh 1.1.0

VERSION=${1:-"1.1.0"}
BUILD_NUMBER=${2:-"4"}

echo "🏷️  Création du tag pour la version $VERSION (Build $BUILD_NUMBER)"
echo ""

# Vérifier qu'on est dans un repo git
if [ ! -d ".git" ]; then
    echo "❌ Pas un repository Git"
    exit 1
fi

# Vérifier qu'il n'y a pas de changements non commités
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Il y a des changements non commités"
    read -p "Commiter maintenant ? (y/N): " commit_choice
    
    if [[ $commit_choice =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "Release v$VERSION (Build $BUILD_NUMBER)

Nouveautés:
- Architecture parent-enfant pour partage CloudKit robuste
- Actions de masse (tout cocher/décocher)
- Corrections bugs synchronisation
- Meilleurs messages d'erreur

Fichiers modifiés:
- PersistenceController.swift (architecture améliorée)
- ShoppingListEntity.swift (nouvelle entité parent)
- GroceryItemEntity.swift (relation vers parent)
- ContentView.swift (actions de masse, détection simulateur)
- SharingView.swift (corrections)

Documentation:
- UPLOAD_NOUVELLE_VERSION.md
- TESTFLIGHT_GUIDE.md
- MARKETING_CONTENT.md
- ARCHITECTURE_AMELIOREE.md
"
        echo "✅ Changements commités"
    else
        echo "❌ Annulé - Commitez vos changements avant de créer un tag"
        exit 1
    fi
fi

# Créer le tag
TAG_NAME="v$VERSION-build$BUILD_NUMBER"
TAG_MESSAGE="Release $VERSION (Build $BUILD_NUMBER)

🎉 Nouveautés:
• Architecture de partage CloudKit améliorée
• Actions de masse
• Corrections de bugs majeurs

📝 Notes:
• Nécessite réinstallation propre
• Architecture parent-enfant
• Synchronisation robuste

🧪 Upload TestFlight:
• Date: $(date +"%d/%m/%Y")
• Build: $BUILD_NUMBER
• Distribution: TestFlight Beta
"

git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"

if [ $? -eq 0 ]; then
    echo "✅ Tag créé: $TAG_NAME"
    echo ""
    echo "📤 Pour pousser le tag sur GitHub/GitLab:"
    echo "   git push origin $TAG_NAME"
    echo ""
    echo "📤 Pour pousser tous les tags:"
    echo "   git push origin --tags"
    echo ""
    
    # Proposer de pousser
    read -p "Pousser le tag maintenant ? (y/N): " push_choice
    if [[ $push_choice =~ ^[Yy]$ ]]; then
        git push origin "$TAG_NAME"
        echo "✅ Tag poussé sur le remote"
    fi
else
    echo "❌ Erreur lors de la création du tag"
    exit 1
fi

# Créer une release note
RELEASE_NOTE_FILE="RELEASE_NOTES_v${VERSION}.md"

cat > "$RELEASE_NOTE_FILE" << EOF
# Release Notes - Version $VERSION (Build $BUILD_NUMBER)

**Date de Release:** $(date +"%d/%m/%Y")
**Type:** Beta TestFlight
**Status:** En test

---

## 🎉 Nouveautés Majeures

### Architecture Parent-Enfant
- Implémentation d'une entité \`ShoppingListEntity\` parent
- Relation one-to-many avec \`GroceryItemEntity\`
- Conforme aux best practices CloudKit d'Apple
- **Impact:** Synchronisation beaucoup plus fiable

### Partage CloudKit Amélioré
- Les nouveaux articles ajoutés APRÈS le partage se synchronisent maintenant correctement
- Meilleurs messages d'erreur si le partage échoue
- Détection automatique du simulateur avec vue explicative
- Interface de partage optimisée

### Actions de Masse
- Marquer tous les articles comme achetés
- Marquer tous comme non achetés
- Supprimer tous les articles achetés en une fois
- Menu dédié dans la barre d'outils

---

## 🐛 Corrections de Bugs

### Bug Critique: Boucle Infinie willSave()
- **Symptôme:** Crash "Failed to process pending changes after 1000 attempts"
- **Cause:** Modification de \`dateModified\` dans \`willSave()\` déclenchait une boucle
- **Solution:** Utilisation de \`setPrimitiveValue()\` pour éviter les notifications KVO
- **Impact:** App beaucoup plus stable

### Bug Majeur: Thread Principal
- **Symptôme:** Crash "Publishing changes from background threads"
- **Cause:** \`objectWillChange.send()\` appelé depuis un thread background
- **Solution:** \`DispatchQueue.main.async { objectWillChange.send() }\`
- **Impact:** Pas de crash lors de la synchronisation

### Bug Mineur: Bouton Partage Silencieux
- **Symptôme:** Clic sur partage ne fait rien dans le simulateur
- **Cause:** CloudKit ne fonctionne pas dans le simulateur
- **Solution:** Vue explicative + détection automatique
- **Impact:** Meilleure expérience utilisateur

---

## 📱 Améliorations

### Gestion d'Erreur
- Messages d'erreur détaillés pour le partage CloudKit
- Alertes explicatives avec solutions
- Instructions claires pour l'utilisateur

### Logging
- Logs détaillés des événements CloudKit
- Meilleur tracking de synchronisation
- Facilite le débogage

### Documentation
- Guide complet TestFlight
- Instructions de mise à jour
- Textes marketing prêts
- Architecture documentée

---

## ⚠️ Breaking Changes

### Migration des Données

**IMPORTANT:** Cette version utilise une nouvelle architecture de données qui n'est **PAS compatible** avec la version 1.0.

**Impact sur les Testeurs:**
- Les données de la version 1.0 (Builds 1-3) ne seront pas migrées
- Réinstallation propre nécessaire
- Les testeurs devront recréer leurs listes

**Raison:**
- Architecture plate → Architecture hiérarchique
- Modèle Core Data complètement revu
- Nécessaire pour un partage CloudKit robuste

**Action requise:**
1. Informer tous les testeurs
2. Documenter dans les notes TestFlight
3. Fournir instructions de migration

---

## 🧪 Tests Requis

### Priorité Haute (Critique)
- [ ] Partage CloudKit sur 2 appareils réels différents
- [ ] Ajout d'article APRÈS avoir créé le partage
- [ ] Synchronisation bidirectionnelle (A → B et B → A)
- [ ] Actions de masse (tout cocher, tout décocher)
- [ ] Stabilité générale (pas de crash)

### Priorité Moyenne (Important)
- [ ] Performance de synchronisation (< 5 secondes)
- [ ] Interface de partage claire et intuitive
- [ ] Messages d'erreur compréhensibles
- [ ] Tri par nom et fréquence
- [ ] Import/Export CSV

### Priorité Basse (Nice to Have)
- [ ] Mode sombre
- [ ] Animations fluides
- [ ] Réactivité générale
- [ ] Expérience utilisateur globale

---

## 📊 Métriques de Succès

### Critères d'Acceptation

**Must Have:**
- ✅ Taux de crash < 1%
- ✅ Partage fonctionne à 100% sur appareils réels
- ✅ Nouveaux items se synchronisent après partage

**Should Have:**
- ✅ Synchronisation < 5 secondes
- ✅ Feedback positif > 80%
- ✅ Aucun bug bloquant

**Nice to Have:**
- ✅ Performance fluide
- ✅ Interface intuitive
- ✅ 0 bugs mineurs

---

## 🔄 Migration Guide (Pour Testeurs)

### Étapes de Migration

1. **Sauvegarde (Optionnel)**
   - Prenez une capture d'écran de votre liste
   - Ou exportez en CSV si disponible

2. **Désinstallation**
   - Maintenez l'icône de l'app
   - Supprimez complètement

3. **Réinstallation**
   - Ouvrez TestFlight
   - Installez la version 1.1
   - Acceptez la mise à jour

4. **Recréation**
   - Recréez votre liste manuellement
   - Testez le partage

### Données Perdues

**Quoi :**
- Toutes les listes créées dans v1.0
- Historique des articles
- Partages existants

**Pourquoi :**
- Architecture incompatible
- Modèle Core Data différent
- Migration complexe non pertinente pour une bêta

**Alternative :**
- Pour une app en production, une migration serait implémentée
- Pour une bêta, reset accepté

---

## 📝 Notes de Version (Pour TestFlight)

### Version Courte

\`\`\`
🎉 Version 1.1 - Améliorations Majeures

✨ NOUVEAU
• Partage CloudKit ultra-robuste
• Actions de masse
• Meilleurs messages d'erreur

🐛 FIXES
• Corrections synchronisation
• Stabilité améliorée

⚠️ Réinstallation requise
\`\`\`

### Version Longue

\`\`\`
Version 1.1 - Architecture Améliorée

Merci de tester cette version majeure !

🎯 PRIORITÉS DE TEST
• Partage sur appareils réels (⚠️ ne fonctionne pas dans simulateur)
• Ajouter un article APRÈS avoir partagé
• Actions de masse (tout cocher/décocher)

✨ NOUVEAUTÉS
• Architecture parent-enfant pour partage robuste
• Synchronisation automatique des nouveaux articles
• Actions rapides (menu ✓ dans la barre)
• Détection simulateur avec vue explicative

🐛 CORRECTIONS
• Fix boucle infinie (crash willSave)
• Fix thread principal (crash synchronisation)
• Meilleure gestion d'erreurs

⚠️ IMPORTANT
Cette version nécessite une réinstallation propre.
Les données de v1.0 ne sont pas compatibles.

💡 COMMENT TESTER LE PARTAGE
1. 2 appareils réels avec comptes iCloud différents
2. Créez liste sur appareil A
3. Partagez avec appareil B
4. Ajoutez article sur A → doit apparaître sur B
5. Cochez sur B → doit se cocher sur A

Merci pour vos retours ! 🙏
\`\`\`

---

## 🚀 Checklist de Release

### Pre-Release
- [x] Code reviewed
- [x] Tests manuels effectués
- [x] Documentation mise à jour
- [x] Changelog créé
- [x] Version incrémentée
- [x] Build incrémenté

### Upload
- [ ] Clean Build effectué
- [ ] Archive créée
- [ ] Validation réussie
- [ ] Upload sur App Store Connect
- [ ] Build apparaît dans TestFlight
- [ ] Notes de version ajoutées

### Post-Upload
- [ ] Testeurs notifiés
- [ ] Canal de feedback ouvert
- [ ] Monitoring crash reports
- [ ] Documentation partagée
- [ ] Git tag créé et poussé

---

## 📞 Support & Feedback

### Canaux de Communication
- **Email:** support@myshoppinglist.com
- **TestFlight:** Feedback intégré
- **GitHub:** Issues (si open source)

### Réponse
- Bugs critiques: < 24h
- Bugs majeurs: < 48h
- Feedback: < 1 semaine

---

## 🎯 Prochaines Étapes

### Version 1.2 (Planifiée)
- [ ] Migration automatique des données
- [ ] Notifications push pour changements
- [ ] Catégories d'articles
- [ ] Recherche dans la liste

### Version 2.0 (Vision)
- [ ] Widget iOS
- [ ] Apple Watch app
- [ ] Siri Shortcuts
- [ ] Statistiques d'achat

---

**Build Date:** $(date +"%d/%m/%Y %H:%M:%S")
**Git Tag:** $TAG_NAME
**TestFlight:** En attente de distribution

---

🎉 **Release prête pour distribution !**
EOF

echo ""
echo "✅ Release notes créées: $RELEASE_NOTE_FILE"
echo ""
echo "📋 Fichiers de la release:"
ls -lh RELEASE_NOTES_* CHANGELOG_* 2>/dev/null | tail -5
echo ""
echo "🎉 Release v$VERSION prête !"
