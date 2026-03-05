//
//  WearLog.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

struct WearLog: Identifiable, Codable {
    let id: String
    let userId: String
    let outfitId: String
    let itemIds: [String]
    let date: Date
    let mood: Mood?
    let notes: String?
    let weather: Weather?
}
