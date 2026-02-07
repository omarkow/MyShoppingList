//
//  ShoppingList.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import Foundation
import SwiftData

@Model
final class ShoppingList {
    var title: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Item.shoppingList)
    var items: [Item] = []

    init(title: String) {
        self.title = title
        self.createdAt = .now
    }

    var uncheckedCount: Int {
        items.filter { !$0.isChecked }.count
    }

    var totalCount: Int {
        items.count
    }
}
