//
//  ClothingItem.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import FirebaseFirestore

struct ClothingItem: Identifiable, Codable {
    @DocumentID var id: String?  // Keep this for Firestore
    let userId: String
    var imageURL: String
    var thumbnailURL: String?
    var category: ClothingCategory
    var colors: [String]
    var brand: String?
    var season: [Season]
    var occasion: [Occasion]
    var notes: String?
    let dateAdded: Date
    var wearCount: Int
    var lastWornDate: Date?
    var isFavorite: Bool
    var metadata: ItemMetadata
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case imageURL
        case thumbnailURL
        case category
        case colors
        case brand
        case season
        case occasion
        case notes
        case dateAdded
        case wearCount
        case lastWornDate
        case isFavorite
        case metadata
    }
    
    var daysSinceWorn: Int? {
            guard let lastWorn = lastWornDate else { return nil }
            return Calendar.current.dateComponents([.day], from: lastWorn, to: Date()).day
        }
}

struct ItemMetadata: Codable {
    var createdAt: Date
    var updatedAt: Date
    
    init() {
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}

// Add same structure to Outfit, WearLog, etc.
