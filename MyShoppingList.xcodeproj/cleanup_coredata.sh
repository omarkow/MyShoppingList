#!/bin/bash

# Script de nettoyage pour résoudre les conflits .xcdatamodeld
# Usage: bash cleanup_coredata.sh

echo "🧹 Nettoyage des fichiers Core Data..."

# Trouver tous les fichiers .xcdatamodeld
echo "📁 Recherche des fichiers .xcdatamodeld..."
find . -name "*.xcdatamodeld" -type d

# Compter combien il y en a
count=$(find . -name "*.xcdatamodeld" -type d | wc -l)

echo "📊 Trouvé $count fichier(s) .xcdatamodeld"

if [ "$count" -gt 1 ]; then
    echo "⚠️  ATTENTION : Plusieurs fichiers .xcdatamodeld trouvés!"
    echo ""
    echo "Veuillez supprimer manuellement les doublons dans Xcode:"
    echo "1. Ouvrez le Project Navigator (⌘+1)"
    echo "2. Trouvez les fichiers dupliqués"
    echo "3. Clic droit → Delete → Move to Trash"
    echo ""
    exit 1
elif [ "$count" -eq 0 ]; then
    echo "❌ Aucun fichier .xcdatamodeld trouvé!"
    echo "📝 Exécutez d'abord: bash setup_coredata.sh"
    exit 1
else
    echo "✅ Un seul fichier .xcdatamodeld trouvé - C'est correct!"
fi

# Nettoyer les Derived Data
echo ""
echo "🧹 Nettoyage des Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/MyShoppingList-*
echo "✅ Derived Data nettoyées"

# Nettoyer le Build
echo ""
echo "🧹 Nettoyage du dossier Build..."
rm -rf build/
echo "✅ Dossier Build nettoyé"

echo ""
echo "🎉 Nettoyage terminé!"
echo ""
echo "📋 Prochaines étapes dans Xcode:"
echo "1. Product → Clean Build Folder (⌘+⇧+K)"
echo "2. Product → Build (⌘+B)"
echo ""
