//
//  CloudSharingManager.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import CloudKit
import SwiftData

/// Manages CloudKit sharing operations for shopping lists.
///
/// SwiftData syncs data automatically to the user's private iCloud database.
/// This manager handles sharing lists with other users via CKShare,
/// creating CloudKit records in a shared zone that mirrors the SwiftData objects.
@Observable
final class CloudSharingManager: @unchecked Sendable {
    static let containerIdentifier = "iCloud.OM.MyShoppingList"

    private let ckContainer: CKContainer
    private let privateDatabase: CKDatabase

    nonisolated init() {
        self.ckContainer = CKContainer(identifier: Self.containerIdentifier)
        self.privateDatabase = ckContainer.privateCloudDatabase
    }

    // MARK: - Zone Management

    /// Creates or fetches a dedicated record zone for sharing a shopping list.
    func ensureSharedZone(for listID: PersistentIdentifier) async throws -> CKRecordZone {
        let zoneName = "SharedList-\(listID.hashValue)"
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)

        return try await privateDatabase.save(zone)
    }

    // MARK: - Share Creation

    /// Creates a CKShare for a shopping list, enabling multi-user collaboration.
    func createShare(for shoppingList: ShoppingList) async throws -> CKShare {
        let zone = try await ensureSharedZone(for: shoppingList.persistentModelID)

        // Create a root CKRecord representing the shopping list
        let listRecordID = CKRecord.ID(
            recordName: "list-\(shoppingList.persistentModelID.hashValue)",
            zoneID: zone.zoneID
        )
        let listRecord = CKRecord(recordType: "SharedShoppingList", recordID: listRecordID)
        listRecord["title"] = shoppingList.title as CKRecordValue
        listRecord["createdAt"] = shoppingList.createdAt as CKRecordValue

        // Create item records as children of the list
        var recordsToSave: [CKRecord] = [listRecord]
        for item in shoppingList.items {
            let itemRecordID = CKRecord.ID(
                recordName: "item-\(item.persistentModelID.hashValue)-\(item.timestamp.timeIntervalSince1970)",
                zoneID: zone.zoneID
            )
            let itemRecord = CKRecord(recordType: "SharedItem", recordID: itemRecordID)
            itemRecord["name"] = item.name as CKRecordValue
            itemRecord["quantity"] = item.quantity as CKRecordValue
            itemRecord["isChecked"] = item.isChecked as CKRecordValue
            itemRecord["category"] = item.category as CKRecordValue
            itemRecord["timestamp"] = item.timestamp as CKRecordValue
            itemRecord.parent = CKRecord.Reference(recordID: listRecordID, action: .none)
            recordsToSave.append(itemRecord)
        }

        // Create the share with read/write permissions
        let share = CKShare(rootRecord: listRecord)
        share[CKShare.SystemFieldKey.title] = shoppingList.title as CKRecordValue
        share.publicPermission = .readWrite
        recordsToSave.append(share)

        // Save all records and the share atomically
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave)
        operation.savePolicy = .changedKeys

        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: share)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            privateDatabase.add(operation)
        }
    }

    // MARK: - Sync Shared Data

    /// Fetches shared shopping list records from CloudKit and imports them into SwiftData.
    func fetchSharedLists(into modelContext: ModelContext) async throws {
        let sharedDB = ckContainer.sharedCloudDatabase

        let query = CKQuery(
            recordType: "SharedShoppingList",
            predicate: NSPredicate(value: true)
        )

        let (results, _) = try await sharedDB.records(matching: query)

        for (_, result) in results {
            guard let record = try? result.get(),
                  let title = record["title"] as? String else {
                continue
            }

            let list = ShoppingList(title: title)
            if let createdAt = record["createdAt"] as? Date {
                list.createdAt = createdAt
            }
            modelContext.insert(list)

            // Fetch child items for this list
            let itemPredicate = NSPredicate(value: true)
            let itemQuery = CKQuery(recordType: "SharedItem", predicate: itemPredicate)
            let (itemResults, _) = try await sharedDB.records(matching: itemQuery)

            for (_, itemResult) in itemResults {
                guard let itemRecord = try? itemResult.get(),
                      let name = itemRecord["name"] as? String else {
                    continue
                }
                let item = Item(
                    name: name,
                    quantity: (itemRecord["quantity"] as? Int) ?? 1,
                    category: (itemRecord["category"] as? String) ?? ""
                )
                item.isChecked = (itemRecord["isChecked"] as? Bool) ?? false
                item.shoppingList = list
                modelContext.insert(item)
            }
        }
    }
}
