//
//  CloudSharingManager.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import CloudKit
import SwiftData

/// High-level API for CloudKit sharing operations.
///
/// Uses PersistenceController's NSPersistentCloudKitContainer for native
/// CloudKit sharing (CKShare), providing automatic bidirectional sync
/// of shared shopping lists between users.
@Observable
final class CloudSharingManager: @unchecked Sendable {
    static let shared = CloudSharingManager()

    let persistenceController: PersistenceController

    nonisolated init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Share Creation

    /// Creates a CKShare for a shopping list using NSPersistentCloudKitContainer's native API.
    /// If a share already exists, returns the existing one.
    func createShare(for shoppingList: ShoppingList) async throws -> CKShare {
        // Check for existing share first
        if let existingShare = persistenceController.existingShare(for: shoppingList) {
            return existingShare
        }

        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.share(shoppingList) { share, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let share = share {
                    continuation.resume(returning: share)
                } else {
                    continuation.resume(throwing: SharingError.shareCreationFailed)
                }
            }
        }
    }

    // MARK: - Share Acceptance

    /// Accepts a CloudKit share invitation from another user.
    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        try await persistenceController.acceptShare(metadata)
    }

    // MARK: - Shared Data Import

    /// Imports shared shopping lists from the Core Data shared store into SwiftData.
    func importSharedLists(into modelContext: ModelContext) {
        let sharedCDLists = persistenceController.fetchSharedLists()

        for cdList in sharedCDLists {
            // Check if we already have this list locally (by matching listID)
            let listID = cdList.listID
            let descriptor = FetchDescriptor<ShoppingList>()
            let existingLists = (try? modelContext.fetch(descriptor)) ?? []
            let alreadyImported = existingLists.contains { list in
                "\(list.persistentModelID.hashValue)" == listID
            }

            guard !alreadyImported else { continue }

            // Create SwiftData objects from Core Data shared objects
            let list = ShoppingList(title: cdList.title)
            list.createdAt = cdList.createdAt
            modelContext.insert(list)

            for cdItem in cdList.itemsArray {
                let item = Item(
                    name: cdItem.name,
                    quantity: Int(cdItem.quantity),
                    category: cdItem.category
                )
                item.isChecked = cdItem.isChecked
                item.timestamp = cdItem.timestamp
                item.shoppingList = list
                modelContext.insert(item)
            }
        }
    }

    // MARK: - Sync Updates

    /// Syncs local changes back to the Core Data shared store for sharing.
    func syncChanges(for shoppingList: ShoppingList) {
        let cdList = persistenceController.findOrCreateCDShoppingList(for: shoppingList)
        let context = persistenceController.container.viewContext

        // Update list properties
        cdList.title = shoppingList.title

        // Sync items: remove old, add current
        if let existingItems = cdList.items as? Set<CDItem> {
            for cdItem in existingItems {
                context.delete(cdItem)
            }
        }

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
    }
}

// MARK: - Errors

enum SharingError: LocalizedError {
    case shareCreationFailed
    case sharedStoreUnavailable

    var errorDescription: String? {
        switch self {
        case .shareCreationFailed:
            return "Impossible de créer le partage. Vérifiez votre connexion iCloud."
        case .sharedStoreUnavailable:
            return "Le magasin de données partagées n'est pas disponible."
        }
    }
}
