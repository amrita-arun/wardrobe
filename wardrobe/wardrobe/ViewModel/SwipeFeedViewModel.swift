//
//  SwipeFeedViewModel.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

@MainActor
class SwipeFeedViewModel: ObservableObject {
    @Published var outfitQueue: [Outfit] = []
    @Published var currentIndex = 0
    @Published var isGenerating = false
    @Published var error: Error?
    
    private let outfitGenerator: OutfitGenerator
    private let outfitRepo: OutfitRepository
    private let feedbackRepo: FeedbackRepository
    private let clothingRepo: ClothingRepository
    private let userId: String
    private var itemsCache: [String: ClothingItem] = [:]
    
    @Published var shownOutfitIds: Set<String> = []
    private var existingOutfitCombos: Set<Set<String>> = []  // Add this - tracks saved outfit combinations
    
    init(
        outfitGenerator: OutfitGenerator,
        outfitRepo: OutfitRepository,
        feedbackRepo: FeedbackRepository,
        userId: String
    ) {
        self.outfitGenerator = outfitGenerator
        self.outfitRepo = outfitRepo
        self.feedbackRepo = feedbackRepo
        self.clothingRepo = ClothingRepository()
        self.userId = userId
    }
    
    func loadExistingOutfits() async {
        do {
            let savedOutfits = try await outfitRepo.fetchOutfits(userId: userId)
            
            // Store the item combinations from saved outfits
            existingOutfitCombos = Set(savedOutfits.map { Set($0.items) })
            
            print("🔵 Loaded \(savedOutfits.count) existing outfits")
            print("🔵 Existing combos: \(existingOutfitCombos.count)")
        } catch {
            print("🔴 Error loading existing outfits: \(error)")
        }
    }
    
    func getItems(for outfit: Outfit) -> [ClothingItem] {
        return outfit.items.compactMap { itemId in
            // Check cache first
            if let cached = itemsCache[itemId] {
                return cached
            }
            
            // If not in cache, try to fetch (this will be nil for now, but will be loaded async)
            Task {
                if let item = try? await clothingRepo.fetchItem(id: itemId) {
                    itemsCache[itemId] = item
                }
            }
            
            return nil
        }
    }
        
        // Update generateOutfits to preload items
    func generateOutfits(temperature: Int? = nil) async {
        guard !isGenerating else { return }
        isGenerating = true
        
        // Load existing outfits if we haven't yet
        if existingOutfitCombos.isEmpty {
            await loadExistingOutfits()
        }
        
        do {
            let context = GenerationContext.current(temperature: temperature)
            let newOutfits = try await outfitGenerator.generateOutfits(
                count: 10,
                context: context
            )
            
            // Filter out duplicates - both from current queue AND from saved outfits
            let uniqueOutfits = newOutfits.filter { outfit in
                let itemSet = Set(outfit.items)
                
                // Check if this combo already exists in saved outfits
                if existingOutfitCombos.contains(itemSet) {
                    print("⚠️ Skipping outfit - already saved")
                    return false
                }
                
                // Check if this combo is already in the current queue
                let isDuplicateInQueue = outfitQueue.contains { existing in
                    Set(existing.items) == itemSet
                }
                
                if isDuplicateInQueue {
                    print("⚠️ Skipping outfit - already in queue")
                    return false
                }
                
                return true
            }
            
            print("🔵 Generated \(newOutfits.count) outfits, \(uniqueOutfits.count) unique")
            
            outfitQueue.append(contentsOf: uniqueOutfits)
            shownOutfitIds.formUnion(uniqueOutfits.map { $0.id })
            
            // Preload all items for these outfits
            await preloadItems(for: uniqueOutfits)
        } catch {
            print("🔴 Error generating outfits: \(error)")
            self.error = error
        }
        
        isGenerating = false
    }
        
        // Add this helper method
    private func preloadItems(for outfits: [Outfit]) async {
        let allItemIds = Set(outfits.flatMap { $0.items })
        
        for itemId in allItemIds {
            if itemsCache[itemId] == nil {
                if let item = try? await clothingRepo.fetchItem(id: itemId) {
                    itemsCache[itemId] = item
                }
            }
        }
        
        // Trigger UI update
        objectWillChange.send()
    }

    func handleSwipe(_ action: SwipeAction, for outfit: Outfit) async {
        print("🔵 Before swipe - currentIndex: \(currentIndex), queue count: \(outfitQueue.count)")
        
        // 1. Record feedback
        let feedback = SwipeFeedback(
            id: UUID().uuidString,
            userId: userId,
            outfitId: outfit.id,
            action: action,
            timestamp: Date(),
            context: SwipeContext(
                temperature: nil,
                dayOfWeek: Date().formatted(.dateTime.weekday(.wide)),
                timeOfDay: getCurrentTimeOfDay()
            )
        )
        
        try? await feedbackRepo.saveFeedback(feedback)
        
        // 2. Handle action
        switch action {
        case .like:
            var likedOutfit = outfit
            likedOutfit.isFavorite = false
            try? await outfitRepo.saveOutfit(likedOutfit)
            
            // Add to existing combos so we don't generate it again
            existingOutfitCombos.insert(Set(outfit.items))
            
        case .superLike:
            var savedOutfit = outfit
            savedOutfit.isFavorite = true
            try? await outfitRepo.saveOutfit(savedOutfit)
            
            // THEN: Mark as worn (creates wear log)
            await markAsWorn(outfit)
            
            // Add to existing combos
            existingOutfitCombos.insert(Set(outfit.items))
            
        case .dislike:
            break
        }
        
        // 3. Move to next
        currentIndex += 1
        print("🔵 After swipe - currentIndex: \(currentIndex), queue count: \(outfitQueue.count)")
        
        // 4. Generate more if running low
        if outfitQueue.count - currentIndex < 3 {
            await generateOutfits()
        }
    }
    
    private func markAsWorn(_ outfit: Outfit) async {
        let wearLog = WearLog(
            id: UUID().uuidString,
            userId: userId,
            outfitId: outfit.id,
            itemIds: outfit.items,
            date: Date(),
            mood: nil,
            notes: nil,
            weather: nil
        )
        
        try? await outfitRepo.saveWearLog(wearLog)
    }
    
    private func getCurrentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "morning" }
        else if hour < 17 { return "afternoon" }
        else { return "evening" }
    }
    
    var currentOutfit: Outfit? {
        guard currentIndex < outfitQueue.count else { return nil }
        return outfitQueue[currentIndex]
    }
    
    var hasMoreOutfits: Bool {
        currentIndex < outfitQueue.count
    }
}
/*
 
 ---
 
 ## How It Works
 
 ### 1. **Outfit Structure Selection**
 ```
 Random choice:
 - 50% chance: Dress + Shoes (+ Outerwear if cold)
 - 50% chance: Top + Bottom + Shoes (+ Outerwear if cold)
 
 */
