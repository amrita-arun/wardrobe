//
//  AppViewModel.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
// ViewModels/AppViewModel.swift

import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    let userId: String
    
    // Shared ViewModels
    let closetViewModel: ClosetViewModel
    let swipeFeedViewModel: SwipeFeedViewModel
    let outfitsViewModel: OutfitsViewModel
    let statsViewModel: StatsViewModel
    
    init(userId: String) {
        self.userId = userId
        
        // Initialize repositories (shared)
        let clothingRepo = ClothingRepository()
        let outfitRepo = OutfitRepository()
        let feedbackRepo = FeedbackRepository()
        let wearLogRepo = WearLogRepository()
        let storageService = StorageService()
        
        // Initialize ViewModels with shared repositories
        self.closetViewModel = ClosetViewModel(
            repository: clothingRepo,
            storageService: storageService,
            userId: userId
        )
        
        let outfitGenerator = OutfitGenerator(
            clothingRepo: clothingRepo,
            feedbackRepo: feedbackRepo,
            userId: userId
        )
        
        self.swipeFeedViewModel = SwipeFeedViewModel(
            outfitGenerator: outfitGenerator,
            outfitRepo: outfitRepo,
            feedbackRepo: feedbackRepo,
            userId: userId
        )
        
        self.outfitsViewModel = OutfitsViewModel(
            repository: outfitRepo,
            userId: userId
        )
        
        self.statsViewModel = StatsViewModel(
            repository: clothingRepo,
            wearLogRepository: wearLogRepo,
            userId: userId
        )
    }
}
