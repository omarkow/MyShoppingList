//
//  MyShoppingListTests.swift
//  MyShoppingListTests
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import Testing
import Foundation
import SwiftData
@testable import MyShoppingList

// MARK: - Item Model Tests

struct ItemTests {

    @Test func itemDefaultValues() throws {
        let item = Item(name: "Lait")
        #expect(item.name == "Lait")
        #expect(item.quantity == 1)
        #expect(item.isChecked == false)
        #expect(item.category == "")
        #expect(item.shoppingList == nil)
    }

    @Test func itemCustomValues() throws {
        let item = Item(name: "Pommes", quantity: 6, category: "Fruits")
        #expect(item.name == "Pommes")
        #expect(item.quantity == 6)
        #expect(item.isChecked == false)
        #expect(item.category == "Fruits")
    }

    @Test func itemToggleChecked() throws {
        let item = Item(name: "Pain")
        #expect(item.isChecked == false)
        item.isChecked = true
        #expect(item.isChecked == true)
        item.isChecked = false
        #expect(item.isChecked == false)
    }

    @Test func itemTimestampIsSet() throws {
        let before = Date()
        let item = Item(name: "Beurre")
        let after = Date()
        #expect(item.timestamp >= before)
        #expect(item.timestamp <= after)
    }

    @Test func itemQuantityUpdate() throws {
        let item = Item(name: "Oeufs", quantity: 6)
        item.quantity = 12
        #expect(item.quantity == 12)
    }
}

// MARK: - ShoppingList Model Tests

struct ShoppingListTests {

    @Test func shoppingListDefaultValues() throws {
        let list = ShoppingList(title: "Courses de la semaine")
        #expect(list.title == "Courses de la semaine")
        #expect(list.items.isEmpty)
    }

    @Test func shoppingListTimestampIsSet() throws {
        let before = Date()
        let list = ShoppingList(title: "Test")
        let after = Date()
        #expect(list.createdAt >= before)
        #expect(list.createdAt <= after)
    }

    @Test func shoppingListCountsWithNoItems() throws {
        let list = ShoppingList(title: "Vide")
        #expect(list.totalCount == 0)
        #expect(list.uncheckedCount == 0)
    }
}

// MARK: - SwiftData Integration Tests

struct SwiftDataIntegrationTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([ShoppingList.self, Item.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func insertAndFetchShoppingList() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let list = ShoppingList(title: "Test List")
        context.insert(list)
        try context.save()

        let descriptor = FetchDescriptor<ShoppingList>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Test List")
    }

    @Test func insertItemIntoShoppingList() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let list = ShoppingList(title: "Courses")
        context.insert(list)

        let item = Item(name: "Lait", quantity: 2, category: "Crèmerie")
        item.shoppingList = list
        context.insert(item)
        try context.save()

        let descriptor = FetchDescriptor<ShoppingList>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)

        let fetchedList = fetched.first!
        #expect(fetchedList.items.count == 1)
        #expect(fetchedList.items.first?.name == "Lait")
        #expect(fetchedList.items.first?.quantity == 2)
        #expect(fetchedList.items.first?.category == "Crèmerie")
    }

    @Test func deleteShoppingListCascadesItems() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let list = ShoppingList(title: "À supprimer")
        context.insert(list)

        let item1 = Item(name: "Article 1")
        item1.shoppingList = list
        context.insert(item1)

        let item2 = Item(name: "Article 2")
        item2.shoppingList = list
        context.insert(item2)
        try context.save()

        // Verify items exist
        let itemDescriptor = FetchDescriptor<Item>()
        let itemsBefore = try context.fetch(itemDescriptor)
        #expect(itemsBefore.count == 2)

        // Delete the list
        context.delete(list)
        try context.save()

        // Items should be cascade-deleted
        let itemsAfter = try context.fetch(itemDescriptor)
        #expect(itemsAfter.count == 0)
    }

    @Test func shoppingListCounts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let list = ShoppingList(title: "Courses")
        context.insert(list)

        let item1 = Item(name: "Lait")
        item1.shoppingList = list
        context.insert(item1)

        let item2 = Item(name: "Pain")
        item2.shoppingList = list
        context.insert(item2)

        let item3 = Item(name: "Beurre")
        item3.isChecked = true
        item3.shoppingList = list
        context.insert(item3)
        try context.save()

        #expect(list.totalCount == 3)
        #expect(list.uncheckedCount == 2)
    }

    @Test func multipleShoppingLists() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let list1 = ShoppingList(title: "Supermarché")
        let list2 = ShoppingList(title: "Boulangerie")
        context.insert(list1)
        context.insert(list2)

        let item1 = Item(name: "Lait")
        item1.shoppingList = list1
        context.insert(item1)

        let item2 = Item(name: "Pain")
        item2.shoppingList = list2
        context.insert(item2)
        try context.save()

        #expect(list1.items.count == 1)
        #expect(list2.items.count == 1)
        #expect(list1.items.first?.name == "Lait")
        #expect(list2.items.first?.name == "Pain")
    }

    @Test func itemCheckedToggleUpdatesCounts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let list = ShoppingList(title: "Test")
        context.insert(list)

        let item = Item(name: "Fromage")
        item.shoppingList = list
        context.insert(item)
        try context.save()

        #expect(list.uncheckedCount == 1)

        item.isChecked = true
        #expect(list.uncheckedCount == 0)

        item.isChecked = false
        #expect(list.uncheckedCount == 1)
    }
}

// MARK: - CloudSharingManager Tests

struct CloudSharingManagerTests {

    @Test func sharingErrorDescriptions() throws {
        let createError = SharingError.shareCreationFailed
        #expect(createError.errorDescription != nil)
        #expect(createError.errorDescription!.contains("partage"))

        let storeError = SharingError.sharedStoreUnavailable
        #expect(storeError.errorDescription != nil)
        #expect(storeError.errorDescription!.contains("partagées"))
    }

    @Test func persistenceControllerModelCreation() throws {
        // Verify the programmatic Core Data model is valid
        let model = PersistenceController.createManagedObjectModel()
        #expect(model.entities.count == 2)

        let entityNames = model.entities.map(\.name)
        #expect(entityNames.contains("CDShoppingList"))
        #expect(entityNames.contains("CDItem"))

        // Verify CDShoppingList attributes
        let listEntity = model.entitiesByName["CDShoppingList"]!
        let listAttrNames = listEntity.attributesByName.keys.sorted()
        #expect(listAttrNames.contains("title"))
        #expect(listAttrNames.contains("createdAt"))
        #expect(listAttrNames.contains("listID"))

        // Verify CDItem attributes
        let itemEntity = model.entitiesByName["CDItem"]!
        let itemAttrNames = itemEntity.attributesByName.keys.sorted()
        #expect(itemAttrNames.contains("name"))
        #expect(itemAttrNames.contains("quantity"))
        #expect(itemAttrNames.contains("isChecked"))
        #expect(itemAttrNames.contains("category"))
        #expect(itemAttrNames.contains("timestamp"))
        #expect(itemAttrNames.contains("itemID"))

        // Verify relationships
        let listRelationships = listEntity.relationshipsByName
        #expect(listRelationships["items"] != nil)
        #expect(listRelationships["items"]?.deleteRule == .cascadeDeleteRule)

        let itemRelationships = itemEntity.relationshipsByName
        #expect(itemRelationships["shoppingList"] != nil)
        #expect(itemRelationships["shoppingList"]?.maxCount == 1)

        // Verify inverse relationships
        #expect(listRelationships["items"]?.inverseRelationship === itemRelationships["shoppingList"])
        #expect(itemRelationships["shoppingList"]?.inverseRelationship === listRelationships["items"])
    }
}
