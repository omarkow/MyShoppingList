//
//  MyShoppingListApp.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct MyShoppingListApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(NotificationHandler.self) private var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(NotificationHandler.self) private var appDelegate
    #endif

    @Environment(\.modelContext) private var modelContext

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ShoppingList.self,
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.OM.MyShoppingList")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// Initialize PersistenceController early so it starts listening for remote changes.
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle incoming CloudKit share invitations
                    handleShareURL(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .sharedDataDidChange)) { _ in
                    // Import shared data when remote changes are detected
                    let manager = CloudSharingManager.shared
                    let context = sharedModelContainer.mainContext
                    manager.importSharedLists(into: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleShareURL(_ url: URL) {
        let operation = CKFetchShareMetadataOperation(shareURLs: [url])
        operation.perShareMetadataResultBlock = { _, result in
            switch result {
            case .success(let metadata):
                Task {
                    try? await CloudSharingManager.shared.acceptShare(metadata)
                }
            case .failure(let error):
                print("Failed to fetch share metadata: \(error.localizedDescription)")
            }
        }
        CKContainer(identifier: "iCloud.OM.MyShoppingList").add(operation)
    }
}
