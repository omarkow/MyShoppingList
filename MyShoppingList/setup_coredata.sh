#!/bin/bash

# Script de configuration pour restructurer le fichier .xcdatamodeld
# Usage: bash setup_coredata.sh

echo "🔧 Configuration du modèle Core Data..."

# Créer la structure correcte
mkdir -p "MyShoppingList.xcdatamodeld/MyShoppingList.xcdatamodel"

# Déplacer le fichier contents s'il existe
if [ -f "MyShoppingList.xcdatamodeldMyShoppingList.xcdatamodelcontents" ]; then
    mv "MyShoppingList.xcdatamodeldMyShoppingList.xcdatamodelcontents" \
       "MyShoppingList.xcdatamodeld/MyShoppingList.xcdatamodel/contents"
    echo "✅ Fichier contents déplacé"
else
    echo "❌ Fichier contents introuvable"
    echo "📝 Créez-le manuellement dans Xcode (File > New > Data Model)"
fi

# Créer un fichier .xccurrentversion
cat > "MyShoppingList.xcdatamodeld/.xccurrentversion" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>_XCCurrentVersionName</key>
	<string>MyShoppingList.xcdatamodel</string>
</dict>
</plist>
EOF

echo "✅ Fichier .xccurrentversion créé"

echo ""
echo "🎉 Configuration terminée!"
echo ""
echo "📋 Prochaines étapes dans Xcode:"
echo "1. Ouvrez votre projet"
echo "2. Ajoutez MyShoppingList.xcdatamodeld au projet (drag & drop)"
echo "3. Build et testez!"
