//
//  ClothingCategory.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

enum ClothingCategory: String, Codable, CaseIterable {
    case top
    case bottom
    case dress
    case outerwear
    case shoes
    case accessory
    
    var displayName: String {
        rawValue.capitalized
    }
}
