//
//  SwipeFeedback.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

struct SwipeFeedback: Codable {
    let id: String
    let userId: String
    let outfitId: String
    let action: SwipeAction
    let timestamp: Date
    let context: SwipeContext
}
