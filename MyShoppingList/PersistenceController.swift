//
//  PersistenceController.swift
//  MyShoppingList
//
//  Gère Core Data + CloudKit avec support du partage
//

import CoreData
import CloudKit
import SwiftUI
import Combine

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    // Pour les previews SwiftUI
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Créer des données de test
        for i in 0..<5 {
            let item = GroceryItemEntity.create(in: context, name: "Item \(i)", frequency: i + 1)
        }
        
        try? context.save()
        return controller
    }()
    
    init(inMemory: Bool = false) {
        // Créer le modèle programmatiquement
        let model = NSManagedObjectModel()
        
        // ========================================
        // ENTITÉ 1: ShoppingListEntity (PARENT)
        // ========================================
        let listEntity = NSEntityDescription()
        listEntity.name = "ShoppingListEntity"
        listEntity.managedObjectClassName = "ShoppingListEntity"
        
        let listIdAttr = NSAttributeDescription()
        listIdAttr.name = "id"
        listIdAttr.attributeType = .UUIDAttributeType
        listIdAttr.isOptional = true
        
        let listNameAttr = NSAttributeDescription()
        listNameAttr.name = "name"
        listNameAttr.attributeType = .stringAttributeType
        listNameAttr.isOptional = false
        listNameAttr.defaultValue = "Ma Liste"
        
        let listDateCreatedAttr = NSAttributeDescription()
        listDateCreatedAttr.name = "dateCreated"
        listDateCreatedAttr.attributeType = .dateAttributeType
        listDateCreatedAttr.isOptional = true
        
        let listDateModifiedAttr = NSAttributeDescription()
        listDateModifiedAttr.name = "dateModified"
        listDateModifiedAttr.attributeType = .dateAttributeType
        listDateModifiedAttr.isOptional = true
        
        let listIsSharedAttr = NSAttributeDescription()
        listIsSharedAttr.name = "isShared"
        listIsSharedAttr.attributeType = .booleanAttributeType
        listIsSharedAttr.isOptional = false
        listIsSharedAttr.defaultValue = false
        
        listEntity.properties = [listIdAttr, listNameAttr, listDateCreatedAttr, listDateModifiedAttr, listIsSharedAttr]
        
        // ========================================
        // ENTITÉ 2: GroceryItemEntity (ENFANT)
        // ========================================
        let itemEntity = NSEntityDescription()
        itemEntity.name = "GroceryItemEntity"
        itemEntity.managedObjectClassName = "GroceryItemEntity"
        
        // Créer les attributs
        // ⚠️ IMPORTANT: Pour CloudKit, id et dateAdded DOIVENT être optionnels
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = true  // ✅ Obligatoire pour CloudKit
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        nameAttr.defaultValue = ""
        
        let isPurchasedAttr = NSAttributeDescription()
        isPurchasedAttr.name = "isPurchased"
        isPurchasedAttr.attributeType = .booleanAttributeType
        isPurchasedAttr.isOptional = false
        isPurchasedAttr.defaultValue = false
        
        let frequencyAttr = NSAttributeDescription()
        frequencyAttr.name = "frequency"
        frequencyAttr.attributeType = .integer64AttributeType
        frequencyAttr.isOptional = false
        frequencyAttr.defaultValue = 1
        
        let dateAddedAttr = NSAttributeDescription()
        dateAddedAttr.name = "dateAdded"
        dateAddedAttr.attributeType = .dateAttributeType
        dateAddedAttr.isOptional = true  // ✅ Obligatoire pour CloudKit
        
        // Attribut pour identifier la zone de partage (conservé pour compatibilité)
        let sharedZoneAttr = NSAttributeDescription()
        sharedZoneAttr.name = "sharedZoneID"
        sharedZoneAttr.attributeType = .stringAttributeType
        sharedZoneAttr.isOptional = true
        sharedZoneAttr.defaultValue = nil
        
        itemEntity.properties = [idAttr, nameAttr, isPurchasedAttr, frequencyAttr, dateAddedAttr, sharedZoneAttr]
        
        // ========================================
        // RELATION PARENT-ENFANT
        // ========================================
        
        // Relation: ShoppingListEntity.items -> GroceryItemEntity (one-to-many)
        let itemsRelationship = NSRelationshipDescription()
        itemsRelationship.name = "items"
        itemsRelationship.destinationEntity = itemEntity
        itemsRelationship.minCount = 0
        itemsRelationship.maxCount = 0  // 0 = unlimited
        itemsRelationship.deleteRule = .cascadeDeleteRule  // Si on supprime la liste, supprimer les items
        
        // Relation inverse: GroceryItemEntity.shoppingList -> ShoppingListEntity (many-to-one)
        let listRelationship = NSRelationshipDescription()
        listRelationship.name = "shoppingList"
        listRelationship.destinationEntity = listEntity
        listRelationship.minCount = 0
        listRelationship.maxCount = 1
        listRelationship.deleteRule = .nullifyDeleteRule  // Si on supprime un item, ne pas supprimer la liste
        
        // Définir les relations inverses
        itemsRelationship.inverseRelationship = listRelationship
        listRelationship.inverseRelationship = itemsRelationship
        
        // Ajouter les relations aux entités
        listEntity.properties.append(itemsRelationship)
        itemEntity.properties.append(listRelationship)
        
        // ========================================
        // FINALISER LE MODÈLE
        // ========================================
        
        model.entities = [listEntity, itemEntity]
        
        print("📊 Modèle Core Data créé avec 2 entités:")
        print("   - ShoppingListEntity (parent)")
        print("   - GroceryItemEntity (enfant)")
        print("   - Relation: 1 ShoppingList -> N GroceryItems")
        
        // Créer le container avec le modèle
        container = NSPersistentCloudKitContainer(name: "MyShoppingList", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configuration CloudKit
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("❌ Pas de store description")
            }
            
            // Activer la synchronisation CloudKit
            // ⚠️ IMPORTANT: Ce nom DOIT correspondre exactement au conteneur dans:
            // Xcode → Signing & Capabilities → iCloud → Containers
            let bundleID = Bundle.main.bundleIdentifier ?? "com.MyShoppingList"
            
            // 🔍 DEBUG: Afficher le Bundle ID détecté
            print("📋 Bundle ID détecté: \(bundleID)")
            
            // ✅ Utilisation du conteneur CloudKit configuré dans Xcode
            // Target → Signing & Capabilities → iCloud → Containers
            let cloudKitID = "iCloud.com.MyShoppingList"
            
            let containerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: cloudKitID
            )
            
            // 🚀 CONFIGURATION POUR PRODUCTION
            // Détection automatique de l'environnement :
            // - Development : pendant le debug depuis Xcode
            // - Production : TestFlight et App Store
            #if DEBUG
            print("🔧 Mode DEBUG : Utilisation de l'environnement Development")
            // En debug, on reste sur Development (par défaut)
            #else
            print("🚀 Mode RELEASE : Utilisation de l'environnement Production")
            // En release (TestFlight/App Store), passer en production n'est pas nécessaire
            // CloudKit utilise automatiquement le bon environnement selon le profil de provisioning
            #endif
            
            description.cloudKitContainerOptions = containerOptions
            
            print("📦 CloudKit Container utilisé: \(cloudKitID)")
            print("   ⚠️ Si vous voyez une erreur 'Bad Container':")
            print("      1. Vérifiez Xcode → Target → Capabilities → iCloud")
            print("      2. Le conteneur '\(cloudKitID)' doit être coché")
            print("      3. Sinon, créez-le avec le bouton '+'")

            
            // Activer le partage CloudKit
            description.cloudKitContainerOptions?.databaseScope = .private
            
            // Options importantes pour le partage
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        // Charger les stores avec gestion d'erreur et retry
        var shouldRetry = false
        var retryCount = 0
        let maxRetries = 2
        
        repeat {
            shouldRetry = false
            
            container.loadPersistentStores { description, error in
                if let error = error as NSError? {
                    // Afficher plus de détails sur l'erreur
                    print("❌ Erreur Core Data détaillée:")
                    print("   Description: \(error.localizedDescription)")
                    print("   Domain: \(error.domain)")
                    print("   Code: \(error.code)")
                    print("   UserInfo: \(error.userInfo)")
                    
                    // En développement, tenter de récupérer en supprimant le store
                    if let storeURL = description.url, retryCount < maxRetries {
                        print("   Store URL: \(storeURL)")
                        
                        // Supprimer tous les fichiers associés
                        let fileManager = FileManager.default
                        let baseURL = storeURL.deletingPathExtension()
                        
                        // Liste de tous les fichiers à supprimer
                        let filesToDelete = [
                            storeURL,
                            URL(fileURLWithPath: baseURL.path + ".sqlite-shm"),
                            URL(fileURLWithPath: baseURL.path + ".sqlite-wal"),
                            URL(fileURLWithPath: baseURL.path + "-shm"),
                            URL(fileURLWithPath: baseURL.path + "-wal")
                        ]
                        
                        for fileURL in filesToDelete {
                            if fileManager.fileExists(atPath: fileURL.path) {
                                try? fileManager.removeItem(at: fileURL)
                                print("   🗑️ Supprimé: \(fileURL.lastPathComponent)")
                            }
                        }
                        
                        print("⚠️ Store corrompu supprimé, tentative \(retryCount + 1)/\(maxRetries)")
                        shouldRetry = true
                        retryCount += 1
                    } else {
                        fatalError("❌ Erreur Core Data irréparable après \(retryCount) tentative(s): \(error.localizedDescription)")
                    }
                } else {
                    print("✅ Core Data chargé: \(description)")
                }
            }
            
            // Attendre un peu avant de réessayer
            if shouldRetry {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
        } while shouldRetry
        
        // Configuration du contexte
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Observer les changements distants
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
        
        // Observer les événements CloudKit pour plus de détails
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container
        )
        
        print("✅ PersistenceController initialisé avec succès")
    }
    
    @objc private func handleCloudKitEvent(_ notification: Notification) {
        if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
            
            print("☁️ Événement CloudKit:")
            print("   Type: \(event.type)")
            print("   Start: \(event.startDate)")
            
            if let endDate = event.endDate {
                print("   End: \(endDate)")
                let duration = endDate.timeIntervalSince(event.startDate)
                print("   Duration: \(String(format: "%.2f", duration))s")
            }
            
            if event.succeeded {
                print("   ✅ Succès")
            } else if let error = event.error {
                print("   ❌ Erreur: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        print("🔄 Changement distant détecté")
        
        // Afficher plus de détails sur la notification
        if let userInfo = notification.userInfo {
            print("   📋 User Info: \(userInfo)")
            
            // Vérifier si c'est un événement CloudKit
            if let storeUUID = userInfo[NSStoreUUIDKey] as? String {
                print("   🏪 Store UUID: \(storeUUID)")
            }
            
            if let historyToken = userInfo[NSPersistentHistoryTokenKey] {
                print("   🕐 History Token présent: \(historyToken)")
            }
        }
        
        // ⚠️ IMPORTANT: Les notifications CloudKit arrivent sur un thread en arrière-plan
        // Il faut passer sur le thread principal pour notifier SwiftUI
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    // MARK: - Fonctions de partage CloudKit (Version Simplifiée)
    
    /// Récupère la liste de courses par défaut
    func getDefaultShoppingList() -> ShoppingListEntity {
        return ShoppingListEntity.fetchOrCreateDefault(in: container.viewContext)
    }
    
    /// Crée un nouveau partage pour TOUS les items
    /// ✅ Version simplifiée: On partage tous les GroceryItemEntity directement
    func createShare() async throws -> CKShare {
        let context = container.viewContext
        
        // Récupérer TOUS les items
        let fetchRequest: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        let allItems = try context.fetch(fetchRequest)
        
        guard !allItems.isEmpty else {
            throw NSError(domain: "MyShoppingList", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Aucun article à partager. Ajoutez au moins un article avant de partager."
            ])
        }
        
        print("📤 Préparation du partage...")
        print("   Articles à partager: \(allItems.count)")
        
        // Vérifier s'il existe déjà un partage (sur le premier item)
        if let existingShare = await fetchExistingShare(for: allItems.first!) {
            print("⚠️ Un partage existe déjà")
            print("   URL du partage: \(existingShare.url?.absoluteString ?? "aucune URL")")
            return existingShare
        }
        
        // ✅ Partager TOUS les items en une seule fois
        print("   🎯 Création du partage pour \(allItems.count) articles...")
        let (sharedObjects, share, _) = try await container.share(allItems, to: nil)
        
        // ⚠️ CONFIGURATION CRITIQUE pour le partage iMessage
        // Ces propriétés DOIVENT être définies pour que le lien fonctionne
        share[CKShare.SystemFieldKey.title] = "Ma Liste de Courses" as CKRecordValue
        share[CKShare.SystemFieldKey.shareType] = "com.myshoppinglist.list" as CKRecordValue
        share.publicPermission = .none // Partage privé uniquement
        
        // ✅ Ajouter une vignette (optionnel mais recommandé)
        if let thumbnailData = createThumbnailData() {
            share[CKShare.SystemFieldKey.thumbnailImageData] = thumbnailData as CKRecordValue
        }
        
        print("✅ CKShare créé dans Core Data")
        print("   🌍 Zone CloudKit: \(share.recordID.zoneID.zoneName)")
        print("   📦 Objets partagés: \(sharedObjects.count)")
        
        // ⚠️ CRITIQUE: Sauvegarder le contexte Core Data IMMÉDIATEMENT
        // Ceci déclenche la synchronisation CloudKit et génère l'URL de partage
        print("   💾 Sauvegarde Core Data pour déclencher sync CloudKit...")
        
        // ✅ Capturer les données nécessaires avant la closure @Sendable
        let zoneID = share.recordID.zoneID.zoneName
        let itemIDs = allItems.map { $0.objectID }
        
        try await context.perform {
            // Marquer tous les items comme partagés en les récupérant par leur objectID
            for objectID in itemIDs {
                if let item = try? context.existingObject(with: objectID) as? GroceryItemEntity {
                    item.sharedZoneID = zoneID
                }
            }
            
            // Marquer la liste virtuelle comme partagée
            let shoppingList = self.getDefaultShoppingList()
            shoppingList.isShared = true
            
            if context.hasChanges {
                try context.save()
                print("   ✅ Core Data sauvegardé - CloudKit va synchroniser")
            }
        }
        
        // ✅ Attendre un court instant pour que CloudKit initialise l'URL
        // (Normalement, l'URL est générée après la première sync)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
        
        // Vérifier si l'URL a été générée
        if share.url != nil {
            print("   ✅ URL de partage générée: \(share.url!.absoluteString)")
        } else {
            print("   ⚠️ URL de partage pas encore disponible (sera générée lors de la présentation)")
        }
        
        print("   👥 Les participants pourront:")
        print("      - Voir tous les articles")
        print("      - Ajouter de nouveaux articles")
        print("      - Modifier et supprimer")
        print("      - Tout se synchronise automatiquement!")
        
        return share
    }
    
    /// Crée une vignette pour le partage
    private func createThumbnailData() -> Data? {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Fond dégradé
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient,
                                                start: .zero,
                                                end: CGPoint(x: size.width, y: size.height),
                                                options: [])
            
            // Icône de liste
            if let icon = UIImage(systemName: "list.bullet.rectangle.fill") {
                let iconSize: CGFloat = 120
                let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                     y: (size.height - iconSize) / 2,
                                     width: iconSize,
                                     height: iconSize)
                UIColor.white.setFill()
                icon.draw(in: iconRect)
            }
        }
        
        return image.pngData()
    }
    
    /// Crée une vignette pour le partage
    private func createThumbnailData() -> Data? {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Fond dégradé
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient,
                                                start: .zero,
                                                end: CGPoint(x: size.width, y: size.height),
                                                options: [])
            
            // Icône de liste
            if let icon = UIImage(systemName: "list.bullet.rectangle.fill") {
                let iconSize: CGFloat = 120
                let iconRect = CGRect(x: (size.width - iconSize) / 2,
                                     y: (size.height - iconSize) / 2,
                                     width: iconSize,
                                     height: iconSize)
                UIColor.white.setFill()
                icon.draw(in: iconRect)
            }
        }
        
        return image.pngData()
    }
    
    /// Récupère le partage existant pour un item
    func fetchExistingShare(for item: GroceryItemEntity) async -> CKShare? {
        do {
            let shares = try container.fetchShares(matching: [item.objectID])
            let share = shares[item.objectID]
            
            if let share = share {
                print("📋 Partage existant trouvé")
                print("   Zone: \(share.recordID.zoneID.zoneName)")
                print("   Participants: \(share.participants.count)")
            }
            
            return share
        } catch {
            print("❌ Erreur récupération share: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Récupère le partage existant (pour compatibilité)
    func fetchExistingShare() async -> CKShare? {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        guard let firstItem = try? context.fetch(fetchRequest).first else {
            return nil
        }
        
        return await fetchExistingShare(for: firstItem)
    }
    
    /// Vérifie si la liste est actuellement partagée
    func isListShared() -> Bool {
        return getDefaultShoppingList().isShared
    }
    
    /// Arrête le partage
    func stopSharing() async throws {
        guard let share = await fetchExistingShare() else {
            print("⚠️ Aucun partage actif trouvé")
            return
        }
        
        guard let store = container.persistentStoreCoordinator.persistentStores.first else {
            throw NSError(domain: "MyShoppingList", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Impossible de trouver le store"
            ])
        }
        
        print("🛑 Arrêt du partage...")
        print("   Zone à supprimer: \(share.recordID.zoneID.zoneName)")
        
        let context = container.viewContext
        
        // Récupérer tous les items et retirer l'ID de zone
        let fetchRequest: NSFetchRequest<GroceryItemEntity> = GroceryItemEntity.fetchRequest()
        let allItems = try context.fetch(fetchRequest)
        
        for item in allItems {
            item.sharedZoneID = nil
        }
        
        // Marquer la liste virtuelle comme non partagée
        let shoppingList = getDefaultShoppingList()
        shoppingList.isShared = false
        
        // Sauvegarder d'abord
        if context.hasChanges {
            try context.save()
        }
        
        // Ensuite purger la zone partagée
        try await container.purgeObjectsAndRecordsInZone(with: share.recordID.zoneID, in: store)
        
        print("✅ Partage arrêté complètement")
        print("   Tous les articles sont maintenant privés")
    }
    
    // MARK: - Fonctions de partage CloudKit (Legacy - pour compatibilité)
    
    /// Vérifie si un item peut être partagé
    func canShare(_ item: GroceryItemEntity) -> Bool {
        return container.canUpdateRecord(forManagedObjectWith: item.objectID)
    }
    
    /// Récupère le partage existant pour un item (legacy)
    func fetchShare(for item: GroceryItemEntity) -> CKShare? {
        guard canShare(item) else { return nil }
        
        do {
            let shares = try container.fetchShares(matching: [item.objectID])
            return shares[item.objectID]
        } catch {
            print("❌ Erreur récupération share: \(error)")
            return nil
        }
    }
    
    // MARK: - Sauvegarde
    
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("✅ Sauvegarde réussie")
        } catch {
            print("❌ Erreur sauvegarde: \(error)")
        }
    }
    
    // MARK: - Gestion de masse
    
    /// Marque tous les articles comme achetés
    func markAllAsPurchased() {
        let shoppingList = getDefaultShoppingList()
        shoppingList.markAllAsPurchased()
        save()
        print("✅ Tous les articles marqués comme achetés (\(shoppingList.totalItems) items)")
    }
    
    /// Marque tous les articles comme non achetés
    func markAllAsNotPurchased() {
        let shoppingList = getDefaultShoppingList()
        shoppingList.markAllAsNotPurchased()
        save()
        print("✅ Tous les articles marqués comme non achetés (\(shoppingList.totalItems) items)")
    }
    
    /// Réinitialise la liste (décocher tous les articles achetés)
    func resetList() {
        markAllAsNotPurchased()
    }
    
    /// Supprime tous les articles achetés
    func deleteAllPurchased() {
        let context = container.viewContext
        let shoppingList = getDefaultShoppingList()
        let purchasedCount = shoppingList.purchasedItems
        
        shoppingList.deleteAllPurchased(in: context)
        save()
        print("✅ \(purchasedCount) articles achetés supprimés")
    }
}
