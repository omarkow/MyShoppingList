#!/bin/bash

# Script de vérification de la configuration CloudKit
# Pour MyShoppingList

echo "🔍 Vérification de la configuration CloudKit Sharing"
echo "=================================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
ERRORS=0
WARNINGS=0
SUCCESS=0

# Fonction pour afficher les résultats
check_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((SUCCESS++))
}

check_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

check_error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

check_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "1️⃣  Vérification des fichiers du projet..."
echo "-------------------------------------------"

# Vérifier que les fichiers existent
if [ -f "PersistenceController.swift" ]; then
    check_success "PersistenceController.swift trouvé"
    
    # Vérifier le conteneur CloudKit
    if grep -q "iCloud.com.MyShoppingList" PersistenceController.swift; then
        check_success "Conteneur CloudKit correctement configuré: iCloud.com.MyShoppingList"
    else
        check_error "Le conteneur CloudKit semble mal configuré"
        check_info "Recherchez 'cloudKitID' dans PersistenceController.swift"
    fi
    
    # Vérifier la configuration du partage
    if grep -q "container.share" PersistenceController.swift; then
        check_success "Fonction de partage présente"
    else
        check_warning "Fonction de partage non trouvée"
    fi
else
    check_error "PersistenceController.swift non trouvé"
fi

if [ -f "ContentView.swift" ]; then
    check_success "ContentView.swift trouvé"
    
    # Vérifier le conteneur dans ContentView
    if grep -q "iCloud.com.MyShoppingList" ContentView.swift; then
        check_success "CloudContainer dans ContentView correspond"
    else
        check_warning "Le CloudContainer dans ContentView pourrait ne pas correspondre"
    fi
else
    check_error "ContentView.swift non trouvé"
fi

if [ -f "SharingView.swift" ]; then
    check_success "SharingView.swift trouvé (UICloudSharingController)"
else
    check_error "SharingView.swift non trouvé"
fi

echo ""
echo "2️⃣  Vérification de la configuration Xcode..."
echo "-------------------------------------------"

# Chercher le fichier .xcodeproj
XCODEPROJ=$(find . -name "*.xcodeproj" -maxdepth 2 | head -n 1)

if [ -n "$XCODEPROJ" ]; then
    check_success "Projet Xcode trouvé: $XCODEPROJ"
    
    # Vérifier les entitlements
    ENTITLEMENTS=$(find . -name "*.entitlements" -maxdepth 3)
    
    if [ -n "$ENTITLEMENTS" ]; then
        check_success "Fichier entitlements trouvé"
        
        for FILE in $ENTITLEMENTS; do
            echo ""
            check_info "Analyse de: $FILE"
            
            # Vérifier iCloud
            if grep -q "com.apple.developer.icloud-container-identifiers" "$FILE"; then
                check_success "Capability iCloud présente"
                
                # Vérifier le conteneur spécifique
                if grep -q "iCloud.com.MyShoppingList" "$FILE"; then
                    check_success "Conteneur iCloud.com.MyShoppingList configuré"
                else
                    check_error "Le conteneur iCloud.com.MyShoppingList n'est PAS dans les entitlements"
                    check_info "Allez dans Xcode → Target → Signing & Capabilities → iCloud"
                fi
            else
                check_error "Capability iCloud MANQUANTE dans les entitlements"
                check_info "Ajoutez iCloud dans Xcode → Target → Signing & Capabilities"
            fi
            
            # Vérifier CloudKit
            if grep -q "CloudKit" "$FILE" || grep -q "com.apple.developer.icloud-services" "$FILE"; then
                if grep -q "CloudKit" "$FILE"; then
                    check_success "CloudKit activé dans les services iCloud"
                fi
            else
                check_error "CloudKit n'est pas activé!"
                check_info "Cochez CloudKit dans Xcode → iCloud capability"
            fi
        done
    else
        check_warning "Aucun fichier .entitlements trouvé"
        check_info "Les entitlements devraient être générés automatiquement"
    fi
    
    # Vérifier Info.plist
    INFOPLIST=$(find . -name "Info.plist" -maxdepth 3 | grep -v "Test")
    
    if [ -n "$INFOPLIST" ]; then
        for PLIST in $INFOPLIST; do
            if [ -f "$PLIST" ]; then
                check_info "Info.plist trouvé: $PLIST"
                
                # Vérifier CKSharingSupported (optionnel)
                if grep -q "CKSharingSupported" "$PLIST"; then
                    check_success "CKSharingSupported configuré"
                else
                    check_warning "CKSharingSupported non trouvé (optionnel mais recommandé)"
                fi
            fi
        done
    fi
else
    check_error "Projet Xcode non trouvé!"
fi

echo ""
echo "3️⃣  Instructions pour la configuration CloudKit Dashboard..."
echo "-------------------------------------------"
check_info "Vous devez vérifier manuellement sur https://icloud.developer.apple.com/"
echo ""
echo "Étapes à suivre:"
echo "  1. Connectez-vous à https://icloud.developer.apple.com/"
echo "  2. Sélectionnez le conteneur: iCloud.com.MyShoppingList"
echo "  3. Vérifiez l'environnement:"
echo "     • Development: pour tester depuis Xcode"
echo "     • Production: pour TestFlight et App Store"
echo ""
echo "  4. ${YELLOW}⚠️  CRITIQUE POUR TESTFLIGHT:${NC}"
echo "     • Allez dans Schema → Development"
echo "     • Cliquez sur 'Deploy to Production...'"
echo "     • Confirmez le déploiement"
echo "     • ${RED}Sans cette étape, le partage ne fonctionnera PAS dans TestFlight!${NC}"
echo ""

echo "4️⃣  Checklist manuelle dans Xcode..."
echo "-------------------------------------------"
echo "À vérifier manuellement dans Xcode:"
echo "  □ Target → Signing & Capabilities → iCloud"
echo "    - CloudKit est coché"
echo "    - iCloud.com.MyShoppingList est dans la liste des conteneurs"
echo "  □ Target → Signing & Capabilities → Background Modes"
echo "    - Remote notifications est coché"
echo "  □ Profil de provisioning correct"
echo "    - App Store profile avec iCloud capability"
echo ""

echo ""
echo "📊 Résumé de la vérification"
echo "=================================================="
echo -e "${GREEN}✅ Succès: $SUCCESS${NC}"
echo -e "${YELLOW}⚠️  Avertissements: $WARNINGS${NC}"
echo -e "${RED}❌ Erreurs: $ERRORS${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 Configuration parfaite! Mais n'oubliez pas:${NC}"
    echo -e "${YELLOW}   📱 Pour TestFlight, déployez le schéma CloudKit en Production${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Configuration presque complète. Vérifiez les avertissements ci-dessus.${NC}"
else
    echo -e "${RED}❌ Des erreurs ont été détectées. Corrigez-les avant de continuer.${NC}"
fi

echo ""
echo "📚 Pour plus d'informations, consultez:"
echo "   → CONFIGURATION_CLOUDKIT_SHARING.md"
echo ""
