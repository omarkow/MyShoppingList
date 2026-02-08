//
//  ShoppingListDetailView.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import SwiftUI
import SwiftData
import CloudKit

struct ShoppingListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var shoppingList: ShoppingList

    @State private var newItemName = ""
    @State private var newItemQuantity = 1
    @State private var newItemCategory = ""
    @State private var showingShareSheet = false
    @State private var activeShare: CKShare?
    @State private var sharingError: String?
    @State private var isSharing = false

    var body: some View {
        List {
            addItemSection
            if !uncheckedItems.isEmpty {
                itemsSection(title: "À acheter", items: uncheckedItems)
            }
            if !checkedItems.isEmpty {
                checkedSection
            }
        }
        .navigationTitle(shoppingList.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: startSharing) {
                    if isSharing {
                        ProgressView()
                    } else {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }
                }
                .disabled(isSharing)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let share = activeShare {
                CloudSharingView(
                    share: share,
                    container: CKContainer(identifier: "iCloud.OM.MyShoppingList"),
                    listTitle: shoppingList.title
                )
            }
        }
        .alert("Erreur de partage", isPresented: .init(
            get: { sharingError != nil },
            set: { if !$0 { sharingError = nil } }
        )) {
            Button("OK") { sharingError = nil }
        } message: {
            if let error = sharingError {
                Text(error)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sharedDataDidChange)) { _ in
            // Sync local changes to the sharing store when remote changes arrive
            CloudSharingManager.shared.syncChanges(for: shoppingList)
        }
    }

    // MARK: - Computed Properties

    private var uncheckedItems: [Item] {
        shoppingList.items
            .filter { !$0.isChecked }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var checkedItems: [Item] {
        shoppingList.items
            .filter { $0.isChecked }
            .sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - View Components

    private var addItemSection: some View {
        Section {
            HStack {
                TextField("Nom de l'article", text: $newItemName)
#if os(iOS)
                    .textInputAutocapitalization(.sentences)
#endif
                    .onSubmit { addItem() }
                Stepper("×\(newItemQuantity)", value: $newItemQuantity, in: 1...99)
                    .fixedSize()
                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !newItemCategory.isEmpty || !newItemName.isEmpty {
                TextField("Catégorie (optionnel)", text: $newItemCategory)
                    .font(.caption)
            }
        }
    }

    private func itemsSection(title: String, items: [Item]) -> some View {
        Section(title) {
            ForEach(items) { item in
                ItemRowView(item: item)
            }
            .onDelete { offsets in
                deleteItems(from: items, at: offsets)
            }
        }
    }

    private var checkedSection: some View {
        Section {
            ForEach(checkedItems) { item in
                ItemRowView(item: item)
            }
            .onDelete { offsets in
                deleteItems(from: checkedItems, at: offsets)
            }
        } header: {
            HStack {
                Text("Terminés")
                Spacer()
                Button("Tout supprimer") {
                    withAnimation {
                        for item in checkedItems {
                            modelContext.delete(item)
                        }
                    }
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Actions

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        withAnimation {
            let item = Item(
                name: name,
                quantity: newItemQuantity,
                category: newItemCategory.trimmingCharacters(in: .whitespaces)
            )
            item.shoppingList = shoppingList
            modelContext.insert(item)
        }
        newItemName = ""
        newItemQuantity = 1
        newItemCategory = ""

        // Sync to sharing store if this list is shared
        CloudSharingManager.shared.syncChanges(for: shoppingList)
    }

    private func deleteItems(from items: [Item], at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
        // Sync deletion to sharing store
        CloudSharingManager.shared.syncChanges(for: shoppingList)
    }

    // MARK: - CloudKit Sharing

    private func startSharing() {
        isSharing = true
        Task {
            do {
                let manager = CloudSharingManager.shared
                let share = try await manager.createShare(for: shoppingList)
                activeShare = share
                showingShareSheet = true
            } catch {
                sharingError = error.localizedDescription
            }
            isSharing = false
        }
    }
}
