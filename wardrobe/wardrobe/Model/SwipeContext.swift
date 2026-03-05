//
//  SwipeContext.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

struct SwipeContext: Codable {
    let temperature: Int?
    let dayOfWeek: String
    let timeOfDay: String // "morning", "afternoon", "evening"
}
