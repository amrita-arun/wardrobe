//
//  Outfit.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

struct Outfit: Identifiable, Codable {
    let id: String
    let userId: String
    let items: [String] // ClothingItem IDs
    let occasions: [Occasion]
    let createdDate: Date
    var isFavorite: Bool
    var wornDates: [Date]
    
    // For outfit generation metadata
    var generatedBy: GenerationSource
    var score: Double? // Algorithm confidence score
    
    enum GenerationSource: String, Codable {
        case user // manually created
        case algorithm // AI generated
    }
}
