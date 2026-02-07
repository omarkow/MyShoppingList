//
//  MyShoppingListApp.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import SwiftUI
import SwiftData

@main
struct MyShoppingListApp: App {
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
