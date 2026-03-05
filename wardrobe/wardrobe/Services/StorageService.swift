//
//  StorageService.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    private let storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, path: String, userId: String) async throws -> String {
        // 1. Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.compressionFailed
        }
        
        // 2. Create storage reference
        // Don't include "clothing/" in path parameter - we add it here
        let ref = storage.reference()
            .child("clothing")
            .child(userId)
            .child("\(path).jpg")  // path is just the item ID
        
        // 3. Upload
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        
        // 4. Get download URL
        let downloadURL = try await ref.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    func deleteImage(at urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidURL
        }
        
        let ref = storage.reference(forURL: url.absoluteString)
        try await ref.delete()
    }
    
    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw StorageError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.invalidImageData
        }
        
        return image
    }
}

enum StorageError: Error {
    case compressionFailed
    case invalidURL
    case invalidImageData
    case uploadFailed
}
