#!/bin/bash

# Script de validation du projet Core Data
# Usage: bash validate_project.sh

echo "🔍 Validation du projet MyShoppingList..."
echo ""

# Compteurs
errors=0
warnings=0

# 1. Vérifier les imports nécessaires
echo "📦 Vérification des imports..."

if grep -q "import Combine" PersistenceController.swift 2>/dev/null; then
    echo "  ✅ Combine importé dans PersistenceController.swift"
else
    echo "  ❌ Combine manquant dans PersistenceController.swift"
    errors=$((errors + 1))
fi

if grep -q "import CoreData" PersistenceController.swift 2>/dev/null; then
    echo "  ✅ CoreData importé dans PersistenceController.swift"
else
    echo "  ❌ CoreData manquant dans PersistenceController.swift"
    errors=$((errors + 1))
fi

# 2. Vérifier les API correctes
echo ""
echo "🔧 Vérification des API Core Data..."

if grep -q "canUpdateRecord(forManagedObjectWith:" PersistenceController.swift 2>/dev/null; then
    echo "  ✅ API canUpdateRecord correcte"
else
    echo "  ⚠️  API canUpdateRecord potentiellement incorrecte"
    warnings=$((warnings + 1))
fi

if grep -q "persistentStoreCoordinator.persistentStores.first" PersistenceController.swift 2>/dev/null; then
    echo "  ✅ Récupération du store correcte"
else
    echo "  ❌ Store non récupéré correctement"
    errors=$((errors + 1))
fi

# 3. Vérifier la structure du projet
echo ""
echo "📁 Vérification de la structure..."

if [ -d "MyShoppingList.xcdatamodeld" ]; then
    echo "  ✅ MyShoppingList.xcdatamodeld existe"
    
    if [ -f "MyShoppingList.xcdatamodeld/.xccurrentversion" ]; then
        echo "  ✅ .xccurrentversion présent"
    else
        echo "  ⚠️  .xccurrentversion manquant"
        warnings=$((warnings + 1))
    fi
    
    if [ -f "MyShoppingList.xcdatamodeld/MyShoppingList.xcdatamodel/contents" ]; then
        echo "  ✅ contents présent"
    else
        echo "  ❌ contents manquant"
        errors=$((errors + 1))
    fi
else
    echo "  ❌ MyShoppingList.xcdatamodeld introuvable"
    errors=$((errors + 1))
fi

# 4. Vérifier les fichiers Swift
echo ""
echo "📝 Vérification des fichiers Swift..."

required_files=("PersistenceController.swift" "GroceryItemEntity.swift" "ContentView.swift" "MyShoppingListApp.swift")

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file présent"
    else
        echo "  ❌ $file manquant"
        errors=$((errors + 1))
    fi
done

# 5. Vérifier qu'il n'y a pas de doublons .xcdatamodeld
echo ""
echo "🔍 Recherche de doublons..."

datamodel_count=$(find . -name "*.xcdatamodeld" -type d 2>/dev/null | wc -l)

if [ "$datamodel_count" -eq 1 ]; then
    echo "  ✅ Un seul fichier .xcdatamodeld trouvé"
elif [ "$datamodel_count" -eq 0 ]; then
    echo "  ❌ Aucun fichier .xcdatamodeld trouvé"
    errors=$((errors + 1))
else
    echo "  ❌ Plusieurs fichiers .xcdatamodeld trouvés ($datamodel_count)"
    find . -name "*.xcdatamodeld" -type d
    errors=$((errors + 1))
fi

# 6. Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RÉSUMÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "🎉 Tout est OK ! Aucun problème détecté."
    echo ""
    echo "Prochaines étapes :"
    echo "1. Ouvrez le projet dans Xcode"
    echo "2. Build (⌘+B)"
    echo "3. Run (⌘+R)"
    exit 0
elif [ $errors -eq 0 ]; then
    echo "⚠️  $warnings avertissement(s) détecté(s)"
    echo "Le projet devrait compiler mais vérifiez les warnings."
    exit 0
else
    echo "❌ $errors erreur(s) et $warnings avertissement(s) détectés"
    echo ""
    echo "Actions recommandées :"
    echo "1. Lisez les erreurs ci-dessus"
    echo "2. Consultez FIXES_COMPILE_ERRORS.md"
    echo "3. Exécutez bash setup_coredata.sh si nécessaire"
    exit 1
fi
