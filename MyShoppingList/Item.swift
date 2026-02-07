//
//  Item.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var name: String = ""
    var quantity: Int = 1
    var isChecked: Bool = false
    var category: String = ""
    var timestamp: Date = Date()
    var shoppingList: ShoppingList?

    init(name: String, quantity: Int = 1, category: String = "") {
        self.name = name
        self.quantity = quantity
        self.isChecked = false
        self.category = category
        self.timestamp = .now
    }
}
