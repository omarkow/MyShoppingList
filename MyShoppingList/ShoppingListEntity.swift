//
//  ShoppingListEntity.swift
//  MyShoppingList
//
//  Entité parent pour gérer le partage CloudKit
//

import Foundation
import CoreData
import CloudKit

@objc(ShoppingListEntity)
public class ShoppingListEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var isShared: Bool
    @NSManaged public var items: NSSet?
    
    // Propriété calculée pour id non-optionnel (pour Identifiable)
    public var idValue: UUID {
        return id ?? UUID()
    }
    
    // Relation typée vers les items
    public var itemsArray: [GroceryItemEntity] {
        let set = items as? Set<GroceryItemEntity> ?? []
        return set.sorted { $0.name < $1.name }
    }
    
    // Statistiques
    public var totalItems: Int {
        return itemsArray.count
    }
    
    public var purchasedItems: Int {
        return itemsArray.filter { $0.isPurchased }.count
    }
    
    public var unpurchasedItems: Int {
        return itemsArray.filter { !$0.isPurchased }.count
    }
    
    // Initialisation avec valeurs par défaut
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        name = "Ma Liste"
        dateCreated = Date()
        dateModified = Date()
        isShared = false
    }
    
    // Mise à jour de la date de modification
    // ⚠️ IMPORTANT: Utiliser setPrimitiveValue pour éviter la boucle infinie
    public override func willSave() {
        super.willSave()
        
        // Ne modifier que si ce n'est pas une insertion et si autre chose a changé
        if !isInserted && isUpdated {
            // Vérifier si dateModified est la seule chose qui a changé
            let changedKeys = changedValues().keys
            let hasRealChanges = changedKeys.contains(where: { $0 != "dateModified" })
            
            if hasRealChanges {
                // Utiliser setPrimitiveValue pour éviter de re-déclencher willSave
                setPrimitiveValue(Date(), forKey: "dateModified")
            }
        }
    }
}

// MARK: - Extensions Core Data

extension ShoppingListEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingListEntity> {
        return NSFetchRequest<ShoppingListEntity>(entityName: "ShoppingListEntity")
    }
    
    // Récupérer ou créer la liste par défaut
    static func fetchOrCreateDefault(in context: NSManagedObjectContext) -> ShoppingListEntity {
        let request = fetchRequest()
        request.fetchLimit = 1
        
        if let existingList = try? context.fetch(request).first {
            return existingList
        }
        
        // Créer une nouvelle liste
        let newList = ShoppingListEntity(context: context)
        newList.id = UUID()
        newList.name = "Ma Liste de Courses"
        newList.dateCreated = Date()
        newList.dateModified = Date()
        newList.isShared = false
        
        return newList
    }
    
    // Ajouter un item à la liste
    func addItem(_ item: GroceryItemEntity) {
        let items = self.mutableSetValue(forKey: "items")
        items.add(item)
    }
    
    // Retirer un item de la liste
    func removeItem(_ item: GroceryItemEntity) {
        let items = self.mutableSetValue(forKey: "items")
        items.remove(item)
    }
}

// MARK: - Gestion de masse

extension ShoppingListEntity {
    
    /// Marque tous les articles comme achetés
    func markAllAsPurchased() {
        for item in itemsArray {
            item.isPurchased = true
        }
    }
    
    /// Marque tous les articles comme non achetés
    func markAllAsNotPurchased() {
        for item in itemsArray {
            item.isPurchased = false
        }
    }
    
    /// Supprime tous les articles achetés
    func deleteAllPurchased(in context: NSManagedObjectContext) {
        let purchasedItems = itemsArray.filter { $0.isPurchased }
        for item in purchasedItems {
            context.delete(item)
        }
    }
}
