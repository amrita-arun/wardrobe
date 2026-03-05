//
//  StatsViewModel.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation

@MainActor
class StatsViewModel: ObservableObject {
    @Published var mostWornItem: ClothingItem?
    @Published var unwornCount: Int = 0
    @Published var unwornItems: [ClothingItem] = []
    @Published var colorDistribution: [String: Int] = [:]
    @Published var wearFrequencyByDay: [String: Int] = [:]
    @Published var totalOutfits: Int = 0
    @Published var items: [ClothingItem] = []  // Add this
    @Published var isLoading = false
    
    private let repository: ClothingRepository
    private let wearLogRepository: WearLogRepository
    private let userId: String
    
    init(repository: ClothingRepository, wearLogRepository: WearLogRepository, userId: String) {
        self.repository = repository
        self.wearLogRepository = wearLogRepository
        self.userId = userId
    }
    
    func loadStats(timeRange: TimeRange = .thisMonth) async {
        isLoading = true
        
        do {
            items = try await repository.fetchAllItems(userId: userId)
            let wearLogs = try await wearLogRepository.fetchLogs(in: timeRange)
            
            calculateStats(items: items, wearLogs: wearLogs)
        } catch {
            print("Error loading stats: \(error)")
        }
        
        isLoading = false
    }
    
    private func calculateStats(items: [ClothingItem], wearLogs: [WearLog]) {
        // Most worn
        mostWornItem = items.max(by: { $0.wearCount < $1.wearCount })
        
        // Unworn items (90+ days)
        unwornItems = items.filter { item in
            guard let lastWorn = item.lastWornDate else { return true }
            let daysSince = Calendar.current.dateComponents([.day], from: lastWorn, to: Date()).day ?? 0
            return daysSince >= 90
        }
        unwornCount = unwornItems.count
        
        // Color distribution
        var colorCounts: [String: Int] = [:]
        for item in items {
            for color in item.colors {
                colorCounts[color, default: 0] += item.wearCount
            }
        }
        colorDistribution = colorCounts
        
        // Wear frequency by day
        var dayCounts: [String: Int] = [:]
        for log in wearLogs {
            let day = log.date.formatted(.dateTime.weekday(.wide))
            dayCounts[day, default: 0] += 1
        }
        wearFrequencyByDay = dayCounts
        
        totalOutfits = wearLogs.count
    }
}
