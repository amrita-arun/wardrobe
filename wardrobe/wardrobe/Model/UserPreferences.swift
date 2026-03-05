//
//  UserPreferences.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

struct UserPreferences: Codable {
    let userId: String
    var preferredColors: [String]
    var avoidedColors: [String]
    var styleProfile: StyleProfile
    var notificationSettings: NotificationSettings
}
