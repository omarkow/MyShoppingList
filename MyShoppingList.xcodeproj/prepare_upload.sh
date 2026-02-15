#!/bin/bash

# Script de Préparation pour Upload TestFlight
# Usage: ./prepare_upload.sh

echo "🚀 Préparation pour Upload TestFlight"
echo "======================================"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Vérifier qu'on est dans le bon dossier
if [ ! -f "MyShoppingList.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Erreur: Exécutez ce script depuis le dossier racine du projet${NC}"
    exit 1
fi

echo -e "${BLUE}📂 Projet détecté${NC}"
echo ""

# 2. Lire les informations actuelles
INFO_PLIST="MyShoppingList/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "1.0.0")
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "1")
else
    # Essayer de lire depuis le projet Xcode
    CURRENT_VERSION="1.0.0"
    CURRENT_BUILD="1"
fi

echo -e "${BLUE}📊 Version actuelle:${NC}"
echo "   Version: $CURRENT_VERSION"
echo "   Build:   $CURRENT_BUILD"
echo ""

# 3. Proposer les nouveaux numéros
NEW_BUILD=$((CURRENT_BUILD + 1))

echo -e "${YELLOW}💡 Numéros suggérés:${NC}"
echo "   Option 1 (patch):     1.0.1 (Build $NEW_BUILD)"
echo "   Option 2 (minor):     1.1.0 (Build $NEW_BUILD)"
echo "   Option 3 (major):     2.0.0 (Build $NEW_BUILD)"
echo "   Option 4 (build ++):  $CURRENT_VERSION (Build $NEW_BUILD)"
echo ""

# 4. Demander quelle option
read -p "Choisissez une option (1-4) ou appuyez sur Entrée pour sauter: " choice
echo ""

case $choice in
    1)
        NEW_VERSION="1.0.1"
        UPDATE_VERSION=true
        ;;
    2)
        NEW_VERSION="1.1.0"
        UPDATE_VERSION=true
        ;;
    3)
        NEW_VERSION="2.0.0"
        UPDATE_VERSION=true
        ;;
    4)
        NEW_VERSION=$CURRENT_VERSION
        UPDATE_VERSION=false
        ;;
    *)
        echo -e "${YELLOW}⏭️  Numéros de version non modifiés${NC}"
        NEW_VERSION=$CURRENT_VERSION
        UPDATE_VERSION=false
        ;;
esac

# 5. Mettre à jour si demandé
if [ "$UPDATE_VERSION" = true ] || [ ! -z "$choice" ]; then
    if [ -f "$INFO_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$INFO_PLIST" 2>/dev/null
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$INFO_PLIST" 2>/dev/null
        echo -e "${GREEN}✅ Numéros mis à jour dans Info.plist${NC}"
        echo "   Nouvelle version: $NEW_VERSION"
        echo "   Nouveau build:    $NEW_BUILD"
    else
        echo -e "${YELLOW}⚠️  Info.plist non trouvé, mettez à jour manuellement dans Xcode${NC}"
        echo "   Target → General → Identity"
        echo "   Version: $NEW_VERSION"
        echo "   Build:   $NEW_BUILD"
    fi
    echo ""
fi

# 6. Vérifier les capabilities
echo -e "${BLUE}🔍 Vérification des Capabilities...${NC}"
PROJECT_FILE="MyShoppingList.xcodeproj/project.pbxproj"

if grep -q "com.apple.developer.icloud-container-identifiers" "$PROJECT_FILE"; then
    echo -e "   ${GREEN}✅ iCloud configuré${NC}"
else
    echo -e "   ${RED}❌ iCloud manquant${NC}"
fi

if grep -q "CloudKit" "$PROJECT_FILE"; then
    echo -e "   ${GREEN}✅ CloudKit activé${NC}"
else
    echo -e "   ${RED}❌ CloudKit manquant${NC}"
fi

if grep -q "remote-notification" "$PROJECT_FILE"; then
    echo -e "   ${GREEN}✅ Background Modes configuré${NC}"
else
    echo -e "   ${YELLOW}⚠️  Background Modes recommandé${NC}"
fi
echo ""

# 7. Nettoyer les build artifacts
echo -e "${BLUE}🧹 Nettoyage...${NC}"
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"

if [ -d "$DERIVED_DATA_PATH" ]; then
    read -p "Nettoyer DerivedData ? (y/N): " clean_choice
    if [[ $clean_choice =~ ^[Yy]$ ]]; then
        rm -rf "$DERIVED_DATA_PATH"/*
        echo -e "   ${GREEN}✅ DerivedData nettoyé${NC}"
    else
        echo -e "   ${YELLOW}⏭️  DerivedData conservé${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  DerivedData non trouvé${NC}"
fi
echo ""

# 8. Vérifier les fichiers importants
echo -e "${BLUE}📋 Vérification des fichiers...${NC}"

FILES_TO_CHECK=(
    "MyShoppingList/PersistenceController.swift"
    "MyShoppingList/GroceryItemEntity.swift"
    "MyShoppingList/ShoppingListEntity.swift"
    "MyShoppingList/ContentView.swift"
)

MISSING_FILES=0
for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ${GREEN}✅ $file${NC}"
    else
        echo -e "   ${RED}❌ $file manquant${NC}"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo -e "${RED}⚠️  $MISSING_FILES fichier(s) manquant(s)${NC}"
else
    echo -e "${GREEN}✅ Tous les fichiers essentiels présents${NC}"
fi
echo ""

# 9. Créer un changelog
CHANGELOG_FILE="CHANGELOG_$(date +%Y%m%d_%H%M%S).txt"

cat > "$CHANGELOG_FILE" << EOF
Version $NEW_VERSION (Build $NEW_BUILD)
Date: $(date +"%d/%m/%Y %H:%M")

🎉 NOUVEAUTÉS
• Architecture de partage améliorée (parent-enfant)
• Actions de masse (tout cocher/décocher)
• Meilleurs messages d'erreur pour le partage

🐛 CORRECTIONS
• Fix boucle infinie willSave()
• Fix thread principal pour objectWillChange
• Amélioration stabilité Core Data

📱 AMÉLIORATIONS
• Synchronisation CloudKit plus robuste
• Interface de partage optimisée
• Détection automatique du simulateur

⚠️ NOTES
• Cette version nécessite une réinstallation propre
• Les données de la version 1.0 ne sont pas compatibles
• Testez particulièrement le partage sur appareils réels

💡 TESTS PRIORITAIRES
1. Partage CloudKit (appareils réels uniquement)
2. Ajout d'article après partage
3. Synchronisation bidirectionnelle
4. Actions de masse
5. Stabilité générale
EOF

echo -e "${GREEN}✅ Changelog créé: $CHANGELOG_FILE${NC}"
echo ""

# 10. Instructions finales
echo -e "${BLUE}📝 Prochaines Étapes:${NC}"
echo ""
echo "1️⃣  Dans Xcode:"
echo "   • Product → Clean Build Folder (⇧⌘K)"
echo "   • Product → Archive"
echo ""
echo "2️⃣  Dans Organizer:"
echo "   • Validate App"
echo "   • Distribute App → App Store Connect → Upload"
echo ""
echo "3️⃣  Dans App Store Connect:"
echo "   • Attendez le processing (10-30 min)"
echo "   • TestFlight → Build $NEW_BUILD"
echo "   • Remplissez 'What to Test' (copiez depuis $CHANGELOG_FILE)"
echo "   • Export Compliance: Non"
echo ""
echo "4️⃣  Notifiez les testeurs:"
echo "   • Informez-les du besoin de réinstallation"
echo "   • Partagez les priorités de test"
echo ""
echo -e "${GREEN}🎉 Prêt pour l'upload !${NC}"
echo ""

# 11. Ouvrir Xcode ?
read -p "Ouvrir Xcode maintenant ? (y/N): " open_xcode
if [[ $open_xcode =~ ^[Yy]$ ]]; then
    open MyShoppingList.xcodeproj
    echo -e "${GREEN}✅ Xcode ouvert${NC}"
fi

echo ""
echo -e "${BLUE}📚 Documentation disponible:${NC}"
echo "   • UPLOAD_NOUVELLE_VERSION.md - Guide complet"
echo "   • TESTFLIGHT_GUIDE.md - Guide TestFlight"
echo "   • MARKETING_CONTENT.md - Textes prêts"
echo ""
echo -e "${GREEN}Bonne chance ! 🍀${NC}"
