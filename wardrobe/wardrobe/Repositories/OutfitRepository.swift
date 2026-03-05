//
//  OutfitRepository.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import FirebaseFirestore

class OutfitRepository {
    private let db = Firestore.firestore()
    private let outfitCollection = "outfits"
    private let wearLogCollection = "wear_logs"
    
    // MARK: - Outfits
    
    func fetchOutfits(userId: String) async throws -> [Outfit] {
        let snapshot = try await db.collection(outfitCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdDate", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Outfit.self)
        }
    }
    
    func fetchFavoriteOutfits(userId: String) async throws -> [Outfit] {
        let snapshot = try await db.collection(outfitCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isFavorite", isEqualTo: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Outfit.self)
        }
    }
    
    func saveOutfit(_ outfit: Outfit) async throws {
        try db.collection(outfitCollection)
            .document(outfit.id)
            .setData(from: outfit)
    }
    
    func updateOutfit(_ outfit: Outfit) async throws {
        try db.collection(outfitCollection)
            .document(outfit.id)
            .setData(from: outfit, merge: true)
    }
    
    func deleteOutfit(id: String) async throws {
        try await db.collection(outfitCollection)
            .document(id)
            .delete()
    }
    
    // MARK: - Wear Logs
    
    func saveWearLog(_ log: WearLog) async throws {
        // 1. Save the wear log
        try db.collection(wearLogCollection)
            .document(log.id)
            .setData(from: log)
        
        // 2. Update outfit's wornDates array
        let outfitRef = db.collection(outfitCollection).document(log.outfitId)
        try await outfitRef.updateData([
            "wornDates": FieldValue.arrayUnion([Timestamp(date: log.date)])
        ])
        
        // 3. Increment wear count for each item
        let clothingRepo = ClothingRepository()
        for itemId in log.itemIds {
            try? await clothingRepo.incrementWearCount(itemId: itemId)
        }
    }
    
    func fetchWearLogs(userId: String, startDate: Date, endDate: Date) async throws -> [WearLog] {
        let snapshot = try await db.collection(wearLogCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: WearLog.self)
        }
    }
}
