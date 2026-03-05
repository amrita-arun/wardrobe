//
//  Weather.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

struct Weather: Codable {
    let temperature: Int // Fahrenheit
    let condition: String // "Sunny", "Rainy", etc.
    let date: Date
}
