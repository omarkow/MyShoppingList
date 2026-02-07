//
//  ContentView.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingList.createdAt, order: .reverse) private var shoppingLists: [ShoppingList]
    @State private var showingAddList = false
    @State private var newListTitle = ""

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(shoppingLists) { list in
                    NavigationLink {
                        ShoppingListDetailView(shoppingList: list)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(list.title)
                                    .font(.headline)
                                Text("\(list.uncheckedCount) restant(s) sur \(list.totalCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if list.uncheckedCount == 0 && list.totalCount > 0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteLists)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
#endif
            .navigationTitle("Mes listes")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: { showingAddList = true }) {
                        Label("Nouvelle liste", systemImage: "plus")
                    }
                }
            }
            .alert("Nouvelle liste", isPresented: $showingAddList) {
                TextField("Titre de la liste", text: $newListTitle)
                Button("Annuler", role: .cancel) { newListTitle = "" }
                Button("Créer") { addList() }
            }
        } detail: {
            Text("Sélectionnez une liste")
                .foregroundStyle(.secondary)
        }
    }

    private func addList() {
        let title = newListTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            newListTitle = ""
            return
        }
        withAnimation {
            let list = ShoppingList(title: title)
            modelContext.insert(list)
        }
        newListTitle = ""
    }

    private func deleteLists(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(shoppingLists[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ShoppingList.self, Item.self], inMemory: true)
}
