//
//  NotificationSettings.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

struct NotificationSettings: Codable {
    var dailyOutfitTime: Date? // What time to send "outfit of the day"
    var unwornItemReminders: Bool
    var enabled: Bool
}
