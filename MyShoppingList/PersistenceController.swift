//
//  PersistenceController.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import CoreData
import CloudKit

// MARK: - Core Data Managed Object Subclasses

@objc(CDShoppingList)
class CDShoppingList: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var createdAt: Date
    @NSManaged var listID: String
    @NSManaged var items: NSSet?

    var itemsArray: [CDItem] {
        (items?.allObjects as? [CDItem]) ?? []
    }
}

@objc(CDItem)
class CDItem: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var quantity: Int64
    @NSManaged var isChecked: Bool
    @NSManaged var category: String
    @NSManaged var timestamp: Date
    @NSManaged var itemID: String
    @NSManaged var shoppingList: CDShoppingList?
}

// MARK: - Persistence Controller

/// Manages an NSPersistentCloudKitContainer with both private and shared stores,
/// enabling full CloudKit sharing between users via CKShare.
///
/// SwiftData handles the app's primary data and private CloudKit sync.
/// This controller provides the sharing layer using Core Data's native
/// NSPersistentCloudKitContainer sharing APIs.
final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer
    let ckContainer = CKContainer(identifier: "iCloud.OM.MyShoppingList")

    private(set) var privateStore: NSPersistentStore?
    private(set) var sharedStore: NSPersistentStore?

    init() {
        let model = Self.createManagedObjectModel()
        container = NSPersistentCloudKitContainer(
            name: "MyShoppingListShared",
            managedObjectModel: model
        )

        let storeDirectory = NSPersistentContainer.defaultDirectoryURL()

        // Private store — syncs with user's private CloudKit database
        let privateDesc = NSPersistentStoreDescription(
            url: storeDirectory.appendingPathComponent("private-sharing.sqlite")
        )
        let privateOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.OM.MyShoppingList"
        )
        privateOptions.databaseScope = .private
        privateDesc.cloudKitContainerOptions = privateOptions
        privateDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDesc.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )

        // Shared store — receives data shared by other users
        let sharedDesc = NSPersistentStoreDescription(
            url: storeDirectory.appendingPathComponent("shared-sharing.sqlite")
        )
        let sharedOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.OM.MyShoppingList"
        )
        sharedOptions.databaseScope = .shared
        sharedDesc.cloudKitContainerOptions = sharedOptions
        sharedDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        sharedDesc.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )

        container.persistentStoreDescriptions = [privateDesc, sharedDesc]

        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                fatalError("Failed to load persistent store: \(error)")
            }

            guard let self = self,
                  let url = description.url,
                  let store = self.container.persistentStoreCoordinator.persistentStore(for: url)
            else { return }

            if description.cloudKitContainerOptions?.databaseScope == .private {
                self.privateStore = store
            } else {
                self.sharedStore = store
            }
        }

        // Merge policy: property-level merge, in-memory (latest) wins
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Observe remote changes for conflict resolution
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }

    // MARK: - Core Data Model (Programmatic)

    static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ShoppingList entity
        let listEntity = NSEntityDescription()
        listEntity.name = "CDShoppingList"
        listEntity.managedObjectClassName = "CDShoppingList"

        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.defaultValue = ""

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.defaultValue = Date()

        let listIDAttr = NSAttributeDescription()
        listIDAttr.name = "listID"
        listIDAttr.attributeType = .stringAttributeType
        listIDAttr.defaultValue = ""

        // Item entity
        let itemEntity = NSEntityDescription()
        itemEntity.name = "CDItem"
        itemEntity.managedObjectClassName = "CDItem"

        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.defaultValue = ""

        let quantityAttr = NSAttributeDescription()
        quantityAttr.name = "quantity"
        quantityAttr.attributeType = .integer64AttributeType
        quantityAttr.defaultValue = 1

        let isCheckedAttr = NSAttributeDescription()
        isCheckedAttr.name = "isChecked"
        isCheckedAttr.attributeType = .booleanAttributeType
        isCheckedAttr.defaultValue = false

        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.defaultValue = ""

        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType
        timestampAttr.defaultValue = Date()

        let itemIDAttr = NSAttributeDescription()
        itemIDAttr.name = "itemID"
        itemIDAttr.attributeType = .stringAttributeType
        itemIDAttr.defaultValue = ""

        // Relationships
        let listToItems = NSRelationshipDescription()
        listToItems.name = "items"
        listToItems.destinationEntity = itemEntity
        listToItems.deleteRule = .cascadeDeleteRule
        listToItems.minCount = 0
        listToItems.maxCount = 0 // toMany

        let itemToList = NSRelationshipDescription()
        itemToList.name = "shoppingList"
        itemToList.destinationEntity = listEntity
        itemToList.deleteRule = .nullifyDeleteRule
        itemToList.minCount = 0
        itemToList.maxCount = 1

        listToItems.inverseRelationship = itemToList
        itemToList.inverseRelationship = listToItems

        listEntity.properties = [titleAttr, createdAtAttr, listIDAttr, listToItems]
        itemEntity.properties = [nameAttr, quantityAttr, isCheckedAttr, categoryAttr,
                                 timestampAttr, itemIDAttr, itemToList]

        model.entities = [listEntity, itemEntity]
        return model
    }

    // MARK: - Sharing Operations

    /// Creates or retrieves a CDShoppingList in the private store matching the SwiftData ShoppingList.
    func findOrCreateCDShoppingList(
        for shoppingList: ShoppingList
    ) -> CDShoppingList {
        let context = container.viewContext
        let listID = "\(shoppingList.persistentModelID.hashValue)"

        let request = NSFetchRequest<CDShoppingList>(entityName: "CDShoppingList")
        request.predicate = NSPredicate(format: "listID == %@", listID)

        if let existing = try? context.fetch(request).first {
            // Update existing record
            existing.title = shoppingList.title
            return existing
        }

        // Create new
        let cdList = CDShoppingList(context: context)
        cdList.title = shoppingList.title
        cdList.createdAt = shoppingList.createdAt
        cdList.listID = listID

        // Mirror items
        for item in shoppingList.items {
            let cdItem = CDItem(context: context)
            cdItem.name = item.name
            cdItem.quantity = Int64(item.quantity)
            cdItem.isChecked = item.isChecked
            cdItem.category = item.category
            cdItem.timestamp = item.timestamp
            cdItem.itemID = "\(item.persistentModelID.hashValue)"
            cdItem.shoppingList = cdList
        }

        try? context.save()
        return cdList
    }

    /// Shares a shopping list using NSPersistentCloudKitContainer's native sharing API.
    func share(
        _ shoppingList: ShoppingList,
        completion: @escaping (CKShare?, Error?) -> Void
    ) {
        let cdList = findOrCreateCDShoppingList(for: shoppingList)

        container.share([cdList], to: nil) { _, share, _, error in
            if let share = share {
                share[CKShare.SystemFieldKey.title] = shoppingList.title as CKRecordValue
                share.publicPermission = .readWrite
            }
            completion(share, error)
        }
    }

    /// Fetches an existing CKShare for a shopping list, if one exists.
    func existingShare(for shoppingList: ShoppingList) -> CKShare? {
        let cdList = findOrCreateCDShoppingList(for: shoppingList)
        guard let shares = try? container.fetchShares(matching: [cdList.objectID]) else {
            return nil
        }
        return shares[cdList.objectID]
    }

    /// Accepts a CloudKit share invitation.
    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        guard let sharedStore = sharedStore else {
            throw NSError(
                domain: "PersistenceController",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Shared store not available"]
            )
        }
        try await container.acceptShareInvitations(from: [metadata], into: sharedStore)
    }

    /// Returns all shared shopping lists received from other users.
    func fetchSharedLists() -> [CDShoppingList] {
        let context = container.viewContext
        let request = NSFetchRequest<CDShoppingList>(entityName: "CDShoppingList")

        guard let sharedStore = sharedStore else { return [] }
        request.affectedStores = [sharedStore]

        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Remote Change Handling

    @objc private func handleRemoteChange(_ notification: Notification) {
        // Post a notification that the app can observe to refresh UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .sharedDataDidChange,
                object: nil
            )
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sharedDataDidChange = Notification.Name("sharedDataDidChange")
}
