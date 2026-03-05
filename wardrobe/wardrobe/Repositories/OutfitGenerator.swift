//
//  OutfitGenerator.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

class OutfitGenerator {
    private let clothingRepo: ClothingRepository
    private let feedbackRepo: FeedbackRepository
    private let userId: String
    
    init(
        clothingRepo: ClothingRepository,
        feedbackRepo: FeedbackRepository,
        userId: String
    ) {
        self.clothingRepo = clothingRepo
        self.feedbackRepo = feedbackRepo
        self.userId = userId
    }
    
    // MARK: - Main Generation Method
    
    // In OutfitGenerator.generateOutfits method:

    func generateOutfits(
        count: Int = 10,
        context: GenerationContext? = nil
    ) async throws -> [Outfit] {
        print("🔵 Starting outfit generation, requesting \(count) outfits")
        
        // 1. Fetch all clothing items
        let allItems = try await clothingRepo.fetchAllItems(userId: userId)
        
        print("🔵 Found \(allItems.count) total clothing items")
        
        guard !allItems.isEmpty else {
            throw GeneratorError.noItems
        }
        
        // 2. Group items by category
        let itemsByCategory = Dictionary(grouping: allItems) { $0.category }
        
        print("🔵 Items by category:")
        for (category, items) in itemsByCategory {
            print("   - \(category.displayName): \(items.count) items")
        }
        
        // 3. Get user preferences from past swipes
        let preferences = try await getUserPreferences()
        
        // 4. Generate outfits
        var generatedOutfits: [Outfit] = []
        var attempts = 0
        let maxAttempts = count * 10
        
        while generatedOutfits.count < count && attempts < maxAttempts {
            attempts += 1
            
            if let outfit = generateSingleOutfit(
                itemsByCategory: itemsByCategory,
                preferences: preferences,
                context: context,
                existingOutfits: generatedOutfits
            ) {
                generatedOutfits.append(outfit)
                print("✅ Generated outfit \(generatedOutfits.count)/\(count)")
            } else {
                print("⚠️ Failed to generate outfit on attempt \(attempts)")
            }
        }
        
        print("🔵 Generation complete: \(generatedOutfits.count) outfits after \(attempts) attempts")
        
        // 5. Score and sort outfits
        var scoredOutfits: [Outfit] = []
        for outfit in generatedOutfits {
            var scored = outfit
            scored.score = await scoreOutfit(outfit, preferences: preferences, context: context)
            scoredOutfits.append(scored)
        }
        scoredOutfits.sort { ($0.score ?? 0) > ($1.score ?? 0) }
        
        return scoredOutfits
    }
    
    // MARK: - Single Outfit Generation
    
    private func generateSingleOutfit(
        itemsByCategory: [ClothingCategory: [ClothingItem]],
        preferences: UserPreferences,
        context: GenerationContext?,
        existingOutfits: [Outfit]
    ) -> Outfit? {
        
        // Decide: Dress-based or Top+Bottom-based
        let useDress = Bool.random() && !(itemsByCategory[.dress]?.isEmpty ?? true)
        
        var selectedItems: [ClothingItem] = []
        
        if useDress {
            // Dress + Shoes (+ optional Outerwear)
            guard let dress = selectItem(
                from: itemsByCategory[.dress] ?? [],
                preferences: preferences,
                context: context
            ) else { return nil }
            
            selectedItems.append(dress)
            
            // Add shoes
            if let shoes = selectItem(
                from: itemsByCategory[.shoes] ?? [],
                preferences: preferences,
                context: context,
                mustMatchWith: [dress]
            ) {
                selectedItems.append(shoes)
            }
            
            // Maybe add outerwear if cold
            if let temp = context?.temperature, temp < 60 {
                if let outerwear = selectItem(
                    from: itemsByCategory[.outerwear] ?? [],
                    preferences: preferences,
                    context: context,
                    mustMatchWith: [dress]
                ) {
                    selectedItems.append(outerwear)
                }
            }
            
        } else {
            // Top + Bottom + Shoes (+ optional Outerwear)
            guard let top = selectItem(
                from: itemsByCategory[.top] ?? [],
                preferences: preferences,
                context: context
            ) else { return nil }
            
            guard let bottom = selectItem(
                from: itemsByCategory[.bottom] ?? [],
                preferences: preferences,
                context: context,
                mustMatchWith: [top]
            ) else { return nil }
            
            selectedItems = [top, bottom]
            
            // Add shoes
            if let shoes = selectItem(
                from: itemsByCategory[.shoes] ?? [],
                preferences: preferences,
                context: context,
                mustMatchWith: [top, bottom]
            ) {
                selectedItems.append(shoes)
            }
            
            // Maybe add outerwear if cold
            if let temp = context?.temperature, temp < 65 {
                if let outerwear = selectItem(
                    from: itemsByCategory[.outerwear] ?? [],
                    preferences: preferences,
                    context: context,
                    mustMatchWith: selectedItems
                ) {
                    selectedItems.append(outerwear)
                }
            }
        }
        
        // Check if this outfit already exists
        let itemIds = selectedItems.compactMap { $0.id }
        if existingOutfits.contains(where: { Set($0.items) == Set(itemIds) }) {
            return nil // Duplicate, try again
        }
        
        // Determine occasions
        let occasions = determineOccasions(for: selectedItems)
        
        return Outfit(
            id: UUID().uuidString,
            userId: userId,
            items: itemIds,
            occasions: occasions,
            createdDate: Date(),
            isFavorite: false,
            wornDates: [],
            generatedBy: .algorithm,
            score: nil
        )
    }
    
    // MARK: - Item Selection Logic
    
    private func selectItem(
        from items: [ClothingItem],
        preferences: UserPreferences,
        context: GenerationContext?,
        mustMatchWith: [ClothingItem] = []
    ) -> ClothingItem? {
        
        var candidates = items
        
        // Filter by season if context available
        if let temp = context?.temperature {
            let appropriateSeasons = seasonsForTemperature(temp)
            candidates = candidates.filter { item in
                item.season.contains(where: { appropriateSeasons.contains($0) })
            }
        }
        
        // Filter by occasion if context available
        if let occasion = context?.occasion {
            candidates = candidates.filter { $0.occasion.contains(occasion) }
        }
        
        // Filter by color compatibility if matching with other items
        if !mustMatchWith.isEmpty {
            candidates = candidates.filter { candidate in
                colorsMatch(candidate.colors, with: mustMatchWith.flatMap { $0.colors })
            }
        }
        
        // If no candidates after filtering, be less strict
        if candidates.isEmpty {
            candidates = items
        }
        
        // Score each candidate
        let scoredCandidates = candidates.map { item -> (item: ClothingItem, score: Double) in
            var score = 0.0
            
            // Freshness bonus (prioritize unworn items)
            if let daysSince = item.daysSinceWorn {
                score += Double(min(daysSince, 90)) / 90.0 * 50 // Max 50 points
            } else {
                score += 60 // Never worn gets highest priority
            }
            
            // Wear count penalty (avoid overused items)
            score -= Double(item.wearCount) * 2
            
            // Favorite bonus
            if item.isFavorite {
                score += 20
            }
            
            // Color preference bonus
            for color in item.colors {
                if preferences.preferredColors.contains(color) {
                    score += 10
                }
                if preferences.avoidedColors.contains(color) {
                    score -= 30
                }
            }
            
            return (item, score)
        }
        
        // Use weighted random selection (not just highest score)
        // This adds variety while still favoring good options
        return weightedRandomSelect(from: scoredCandidates)
    }
    
    // MARK: - Scoring
    
    private func scoreOutfit(
        _ outfit: Outfit,
        preferences: UserPreferences,
        context: GenerationContext?
    ) async -> Double {
        var score = 50.0 // Base score
        
        // Get items
        var items: [ClothingItem] = []
        for itemId in outfit.items {
            if let item = try? await clothingRepo.fetchItem(id: itemId) {
                items.append(item)
            }
        }
        guard !items.isEmpty else { return score }
        
        // Color harmony bonus
        let allColors = items.flatMap { $0.colors }
        if hasColorHarmony(allColors) {
            score += 20
        }
        
        // Freshness bonus (average days since worn)
        let avgDaysSinceWorn = items.compactMap { $0.daysSinceWorn }.reduce(0, +) / max(items.count, 1)
        score += Double(min(avgDaysSinceWorn, 60)) / 60.0 * 30
        
        // Context fit bonus
        if let context = context {
            if let temp = context.temperature {
                let appropriateSeasons = seasonsForTemperature(temp)
                let seasonMatch = items.allSatisfy { item in
                    item.season.contains(where: { appropriateSeasons.contains($0) })
                }
                if seasonMatch {
                    score += 15
                }
            }
            
            if let occasion = context.occasion {
                if items.allSatisfy({ $0.occasion.contains(occasion) }) {
                    score += 15
                }
            }
        }
        
        // Style coherence (all items share at least one occasion)
        let sharedOccasions = items.reduce(Set(Occasion.allCases)) { result, item in
            result.intersection(item.occasion)
        }
        if !sharedOccasions.isEmpty {
            score += 10
        }
        
        return score
    }
    
    // MARK: - Helper Methods
    
    private func colorsMatch(_ colors1: [String], with colors2: [String]) -> Bool {
        // Simplified color matching - check if colors are compatible
        
        // Neutrals match everything
        let neutrals = ["#000000", "#FFFFFF", "#808080", "#A9A9A9", "#D3D3D3", "#2F4F4F"]
        
        let hasNeutral1 = colors1.contains(where: { neutrals.contains($0) })
        let hasNeutral2 = colors2.contains(where: { neutrals.contains($0) })
        
        if hasNeutral1 || hasNeutral2 {
            return true
        }
        
        // Check for complementary or analogous colors
        // For MVP, allow all combinations except clashing primaries
        let primaries1 = colors1.filter { !neutrals.contains($0) }
        let primaries2 = colors2.filter { !neutrals.contains($0) }
        
        // Simple rule: if both have strong colors, they should share at least one
        if primaries1.count > 0 && primaries2.count > 0 {
            return Set(primaries1).intersection(primaries2).count > 0 || primaries1.count + primaries2.count <= 2
        }
        
        return true
    }
    
    private func hasColorHarmony(_ colors: [String]) -> Bool {
        // Outfit has good color harmony if:
        // - Mostly neutrals with one accent color, OR
        // - Related colors (this is simplified)
        
        let neutrals = ["#000000", "#FFFFFF", "#808080", "#A9A9A9", "#D3D3D3", "#2F4F4F"]
        let nonNeutrals = colors.filter { !neutrals.contains($0) }
        
        // Good if mostly neutrals with 0-2 accent colors
        return nonNeutrals.count <= 2
    }
    
    private func seasonsForTemperature(_ temp: Int) -> [Season] {
        switch temp {
        case ..<40:
            return [.winter]
        case 40..<60:
            return [.fall, .winter, .spring]
        case 60..<75:
            return [.spring, .fall]
        case 75...:
            return [.summer, .spring]
        default:
            return Season.allCases
        }
    }
    
    private func determineOccasions(for items: [ClothingItem]) -> [Occasion] {
        // Find occasions shared by all items
        let sharedOccasions = items.reduce(Set(items.first?.occasion ?? [])) { result, item in
            result.intersection(item.occasion)
        }
        
        return Array(sharedOccasions)
    }
    
    private func weightedRandomSelect(from candidates: [(item: ClothingItem, score: Double)]) -> ClothingItem? {
        guard !candidates.isEmpty else { return nil }
        
        // Convert scores to weights (handle negative scores)
        let minScore = candidates.map { $0.score }.min() ?? 0
        let weights = candidates.map { max($0.score - minScore + 1, 1) }
        let totalWeight = weights.reduce(0, +)
        
        // Random selection weighted by score
        let random = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if random < cumulative {
                return candidates[index].item
            }
        }
        
        return candidates.last?.item
    }
    
    private func getUserPreferences() async throws -> UserPreferences {
        // For now, return empty preferences
        // Later we'll learn from swipe feedback
        return UserPreferences(
            userId: userId,
            preferredColors: [],
            avoidedColors: [],
            styleProfile: .casual,
            notificationSettings: NotificationSettings(
                dailyOutfitTime: nil,
                unwornItemReminders: false,
                enabled: false
            )
        )
    }
}

// MARK: - Supporting Types

struct GenerationContext {
    let temperature: Int?
    let occasion: Occasion?
    let dayOfWeek: String
    let timeOfDay: String // "morning", "afternoon", "evening"
    
    static func current(temperature: Int? = nil, occasion: Occasion? = nil) -> GenerationContext {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        if hour < 12 { timeOfDay = "morning" }
        else if hour < 17 { timeOfDay = "afternoon" }
        else { timeOfDay = "evening" }
        
        return GenerationContext(
            temperature: temperature,
            occasion: occasion,
            dayOfWeek: Date().formatted(.dateTime.weekday(.wide)),
            timeOfDay: timeOfDay
        )
    }
}

enum GeneratorError: Error {
    case noItems
    case insufficientItems
    case generationFailed
}
