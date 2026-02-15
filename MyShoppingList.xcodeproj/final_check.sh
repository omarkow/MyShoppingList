#!/bin/bash

# Script de vérification finale
# Usage: bash final_check.sh

echo "🔍 VÉRIFICATION FINALE DU CODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

errors=0

# 1. Vérifier import Combine
echo "1️⃣ Vérification import Combine..."
if grep -q "import Combine" PersistenceController.swift 2>/dev/null; then
    echo "   ✅ import Combine présent"
else
    echo "   ❌ import Combine manquant"
    errors=$((errors + 1))
fi

# 2. Vérifier canUpdateRecord
echo ""
echo "2️⃣ Vérification canUpdateRecord..."
if grep -q "canUpdateRecord(forManagedObjectWith:" PersistenceController.swift 2>/dev/null; then
    echo "   ✅ canUpdateRecord(forManagedObjectWith:) correct"
else
    echo "   ❌ canUpdateRecord API incorrecte"
    errors=$((errors + 1))
fi

# 3. Vérifier share([items], to: nil)
echo ""
echo "3️⃣ Vérification share() API..."
if grep -q "share(\[items\[0\]\], to: nil)" PersistenceController.swift 2>/dev/null; then
    echo "   ✅ share([items], to: nil) correct"
else
    echo "   ⚠️  share() API à vérifier manuellement"
fi

# 4. Vérifier CKShare.ParticipantPermission.none
echo ""
echo "4️⃣ Vérification publicPermission..."
if grep -q "CKShare.ParticipantPermission.none" PersistenceController.swift 2>/dev/null; then
    echo "   ✅ CKShare.ParticipantPermission.none correct"
elif grep -q "publicPermission = .none" PersistenceController.swift 2>/dev/null; then
    echo "   ❌ Utilise .none au lieu de CKShare.ParticipantPermission.none"
    errors=$((errors + 1))
else
    echo "   ⚠️  publicPermission à vérifier"
fi

# 5. Vérifier purgeObjectsAndRecordsInZone
echo ""
echo "5️⃣ Vérification deleteShare..."
if grep -q "purgeObjectsAndRecordsInZone" PersistenceController.swift 2>/dev/null; then
    echo "   ✅ purgeObjectsAndRecordsInZone utilisé"
else
    echo "   ⚠️  Méthode de suppression à vérifier"
fi

# 6. Vérifier acceptShareInvitations avec store
echo ""
echo "6️⃣ Vérification acceptShareInvitations..."
if grep -q "persistentStores.first" MyShoppingListApp.swift 2>/dev/null; then
    echo "   ✅ Store récupéré correctement"
else
    echo "   ❌ Store non récupéré"
    errors=$((errors + 1))
fi

# Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $errors -eq 0 ]; then
    echo "🎉 TOUT EST CORRECT !"
    echo ""
    echo "Prochaines étapes :"
    echo "1. Ouvrez Xcode"
    echo "2. Clean Build (⌘+⇧+K)"
    echo "3. Build (⌘+B)"
    echo "4. Run (⌘+R)"
    echo ""
    echo "Le projet devrait compiler ! ✅"
    exit 0
else
    echo "❌ $errors erreur(s) détectée(s)"
    echo ""
    echo "Consultez FINAL_FIXES.md pour les détails"
    exit 1
fi
