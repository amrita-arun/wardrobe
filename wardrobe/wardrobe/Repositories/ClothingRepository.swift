//
//  ClothingRepository.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import FirebaseFirestore

class ClothingRepository {
    private let db = Firestore.firestore()
    private let collection = "clothing_items"
    
    // MARK: - Fetch
    
    func fetchAllItems(userId: String) async throws -> [ClothingItem] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "dateAdded", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ClothingItem.self)
        }
    }
    
    func fetchItem(id: String) async throws -> ClothingItem {
        let document = try await db.collection(collection)
            .document(id)
            .getDocument()
        
        guard let item = try? document.data(as: ClothingItem.self) else {
            throw RepositoryError.itemNotFound
        }
        
        return item
    }
    
    func fetchItems(category: ClothingCategory, userId: String) async throws -> [ClothingItem] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("category", isEqualTo: category.rawValue)
            .order(by: "dateAdded", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ClothingItem.self)
        }
    }
    
    func fetchUnwornItems(userId: String, daysSince: Int = 90) async throws -> [ClothingItem] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysSince, to: Date())!
        
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("lastWornDate", isLessThan: Timestamp(date: cutoffDate))
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ClothingItem.self)
        }
    }
    
    // MARK: - Write
    
    func saveItem(_ item: ClothingItem) async throws {
        try db.collection(collection)
            .document(item.id ?? "")
            .setData(from: item)
    }
    
    func updateItem(_ item: ClothingItem) async throws {
        var updatedItem = item
        //updatedItem.metadata.updatedAt = Date()
        
        try db.collection(collection)
            .document(item.id ?? "")
            .setData(from: updatedItem, merge: true)
    }
    
    func incrementWearCount(itemId: String) async throws {
        let docRef = db.collection(collection).document(itemId)
        
        try await docRef.updateData([
            "wearCount": FieldValue.increment(Int64(1)),
            "lastWornDate": Timestamp(date: Date())
        ])
    }
    
    func deleteItem(id: String) async throws {
        try await db.collection(collection)
            .document(id)
            .delete()
    }
    
    // MARK: - Real-time Listener
    
    func observeItems(userId: String, onChange: @escaping ([ClothingItem]) -> Void) -> ListenerRegistration {
        return db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "dateAdded", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else { return }
                
                let items = snapshot.documents.compactMap { doc in
                    try? doc.data(as: ClothingItem.self)
                }
                
                onChange(items)
            }
    }
}

enum RepositoryError: Error {
    case itemNotFound
    case invalidData
    case unauthorized
}
