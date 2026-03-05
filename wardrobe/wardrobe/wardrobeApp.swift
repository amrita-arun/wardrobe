//
//  wardrobeApp.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct wardrobeApp: App {
    
    
    init() {
        FirebaseApp.configure()
        
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        Firestore.firestore().settings = settings
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
        }
    }
}
