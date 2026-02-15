//
//  GroceryItemEntity.swift
//  MyShoppingList
//
//  Core Data entity pour remplacer SwiftData
//

import Foundation
import CoreData
import CloudKit

@objc(GroceryItemEntity)
public class GroceryItemEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?  // Optional pour CloudKit
    @NSManaged public var name: String
    @NSManaged public var isPurchased: Bool
    @NSManaged public var frequency: Int64
    @NSManaged public var dateAdded: Date?  // Optional pour CloudKit
    @NSManaged public var sharedZoneID: String?  // Pour identifier la zone de partage
    @NSManaged public var shoppingList: ShoppingListEntity?  // ✅ Relation vers le parent
    
    // Propriété calculée pour faciliter l'utilisation
    public var frequencyInt: Int {
        get { Int(frequency) }
        set { frequency = Int64(newValue) }
    }
    
    // Propriété calculée pour id non-optionnel (pour Identifiable)
    public var idValue: UUID {
        return id ?? UUID()
    }
    
    // Vérifie si l'item est dans une zone partagée
    public var isShared: Bool {
        return shoppingList?.isShared ?? false
    }
    
    // Initialisation avec valeurs par défaut
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        name = ""
        isPurchased = false
        frequency = 1
        dateAdded = Date()
        sharedZoneID = nil
    }
}

// Extension pour faciliter la création
extension GroceryItemEntity {
    static func create(in context: NSManagedObjectContext, name: String, frequency: Int = 1, shoppingList: ShoppingListEntity? = nil) -> GroceryItemEntity {
        let item = GroceryItemEntity(context: context)
        item.id = UUID()
        item.name = name
        item.isPurchased = false
        item.frequencyInt = frequency
        item.dateAdded = Date()
        
        // Si une liste est fournie, l'ajouter
        if let list = shoppingList {
            item.shoppingList = list
        } else {
            // Sinon, récupérer ou créer la liste par défaut
            let defaultList = ShoppingListEntity.fetchOrCreateDefault(in: context)
            item.shoppingList = defaultList
        }
        
        return item
    }
    
    // Fetch request typé
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItemEntity> {
        return NSFetchRequest<GroceryItemEntity>(entityName: "GroceryItemEntity")
    }
    
    // Fetch tous les items triés
    static func fetchAll(in context: NSManagedObjectContext, sortBy keyPath: String = "name", ascending: Bool = true) -> [GroceryItemEntity] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: keyPath, ascending: ascending)]
        return (try? context.fetch(request)) ?? []
    }
    
    // Fetch tous les items d'une liste spécifique
    static func fetchAll(in context: NSManagedObjectContext, for shoppingList: ShoppingListEntity, sortBy keyPath: String = "name", ascending: Bool = true) -> [GroceryItemEntity] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "shoppingList == %@", shoppingList)
        request.sortDescriptors = [NSSortDescriptor(key: keyPath, ascending: ascending)]
        return (try? context.fetch(request)) ?? []
    }
}
