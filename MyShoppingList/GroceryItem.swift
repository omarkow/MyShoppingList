//
//  GroceryItem.swift
//  MyShoppingList
//
//  Created by Olivier Markowitch on 21/12/2025.
//


import Foundation
import SwiftData

@Model
class GroceryItem {
    // CloudKit préfère que les identifiants ne soient pas des constantes
    var id: UUID = UUID()
    var name: String = ""
    var isPurchased: Bool = false
    var frequency: Int = 1
    var dateAdded: Date = Date()
    
    init(name: String, frequency: Int = 1) {
        self.name = name
        self.frequency = frequency
        self.dateAdded = Date()
    }
}
