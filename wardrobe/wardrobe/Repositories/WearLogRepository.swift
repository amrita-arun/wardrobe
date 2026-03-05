//
//  WearLogRepository.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import FirebaseFirestore

class WearLogRepository {
    private let db = Firestore.firestore()
    private let collection = "wear_logs"
    
    // MARK: - Create
    
    func saveWearLog(_ log: WearLog) async throws {
        try db.collection(collection)
            .document(log.id)
            .setData(from: log)
    }
    
    // MARK: - Read
    
    func fetchWearLog(id: String) async throws -> WearLog {
        let document = try await db.collection(collection)
            .document(id)
            .getDocument()
        
        guard let log = try? document.data(as: WearLog.self) else {
            throw RepositoryError.itemNotFound
        }
        
        return log
    }
    
    func fetchLogs(userId: String) async throws -> [WearLog] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: WearLog.self)
        }
    }
    
    func fetchLogs(userId: String, startDate: Date, endDate: Date) async throws -> [WearLog] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: WearLog.self)
        }
    }
    
    func fetchLogs(in timeRange: TimeRange) async throws -> [WearLog] {
        let startDate = timeRange.startDate
        let endDate = Date()
        
        let snapshot = try await db.collection(collection)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: WearLog.self)
        }
    }
    
    func fetchLogsForOutfit(outfitId: String, userId: String) async throws -> [WearLog] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("outfitId", isEqualTo: outfitId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: WearLog.self)
        }
    }
    
    func fetchLogsForItem(itemId: String, userId: String) async throws -> [WearLog] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("itemIds", arrayContains: itemId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: WearLog.self)
        }
    }
    
    // MARK: - Update
    
    func updateWearLog(_ log: WearLog) async throws {
        try db.collection(collection)
            .document(log.id)
            .setData(from: log, merge: true)
    }
    
    func updateMood(logId: String, mood: Mood) async throws {
        try await db.collection(collection)
            .document(logId)
            .updateData([
                "mood": mood.rawValue
            ])
    }
    
    func updateNotes(logId: String, notes: String) async throws {
        try await db.collection(collection)
            .document(logId)
            .updateData([
                "notes": notes
            ])
    }
    
    // MARK: - Delete
    
    func deleteWearLog(id: String) async throws {
        try await db.collection(collection)
            .document(id)
            .delete()
    }
    
    // MARK: - Analytics Helpers
    
    func getTotalWears(userId: String) async throws -> Int {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    func getWearsInDateRange(userId: String, startDate: Date, endDate: Date) async throws -> Int {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    func getMostWornItems(userId: String, limit: Int = 10) async throws -> [(itemId: String, count: Int)] {
        let logs = try await fetchLogs(userId: userId)
        
        // Count occurrences of each item
        var itemCounts: [String: Int] = [:]
        for log in logs {
            for itemId in log.itemIds {
                itemCounts[itemId, default: 0] += 1
            }
        }
        
        // Sort by count and take top N
        return itemCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    func getWearsByDayOfWeek(userId: String) async throws -> [String: Int] {
        let logs = try await fetchLogs(userId: userId)
        
        var dayCount: [String: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full day name
        
        for log in logs {
            let dayName = dateFormatter.string(from: log.date)
            dayCount[dayName, default: 0] += 1
        }
        
        return dayCount
    }
}

// MARK: - TimeRange Enum

enum TimeRange: Hashable, Equatable {
    case thisWeek
    case thisMonth
    case thisYear
    case allTime
    case custom(startDate: Date, endDate: Date)
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .thisWeek:
            return calendar.date(byAdding: .day, value: -7, to: now)!
        case .thisMonth:
            return calendar.date(byAdding: .month, value: -1, to: now)!
        case .thisYear:
            return calendar.date(byAdding: .year, value: -1, to: now)!
        case .allTime:
            return .distantPast
        case .custom(let startDate, _):
            return startDate
        }
    }
    
    var endDate: Date {
        switch self {
        case .custom(_, let endDate):
            return endDate
        default:
            return Date()
        }
    }
    
    var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .thisYear: return "This Year"
        case .allTime: return "All Time"
        case .custom: return "Custom"
        }
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        switch self {
        case .thisWeek:
            hasher.combine("thisWeek")
        case .thisMonth:
            hasher.combine("thisMonth")
        case .thisYear:
            hasher.combine("thisYear")
        case .allTime:
            hasher.combine("allTime")
        case .custom(let startDate, let endDate):
            hasher.combine("custom")
            hasher.combine(startDate)
            hasher.combine(endDate)
        }
    }
    
    // Implement Equatable
    static func == (lhs: TimeRange, rhs: TimeRange) -> Bool {
        switch (lhs, rhs) {
        case (.thisWeek, .thisWeek),
             (.thisMonth, .thisMonth),
             (.thisYear, .thisYear),
             (.allTime, .allTime):
            return true
        case (.custom(let lStart, let lEnd), .custom(let rStart, let rEnd)):
            return lStart == rStart && lEnd == rEnd
        default:
            return false
        }
    }
}
