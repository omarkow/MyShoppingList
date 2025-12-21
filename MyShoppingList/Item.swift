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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
