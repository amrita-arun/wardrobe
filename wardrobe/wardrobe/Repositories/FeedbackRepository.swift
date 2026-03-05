//
//  FeedbackRepository.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import FirebaseFirestore

class FeedbackRepository {
    private let db = Firestore.firestore()
    private let collection = "swipe_feedback"
    
    func saveFeedback(_ feedback: SwipeFeedback) async throws {
        try db.collection(collection)
            .document(feedback.id)
            .setData(from: feedback)
    }
    
    func fetchFeedback(userId: String, limit: Int = 100) async throws -> [SwipeFeedback] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: SwipeFeedback.self)
        }
    }
    
    // For ML training later
    func fetchAllFeedback(userId: String) async throws -> [SwipeFeedback] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: SwipeFeedback.self)
        }
    }
}
