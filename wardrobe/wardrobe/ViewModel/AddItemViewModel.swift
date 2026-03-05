//
//  AddItemViewModel.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI
import PhotosUI

@MainActor
class AddItemViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var processedImage: UIImage? // After background removal
    @Published var category: ClothingCategory = .top
    @Published var detectedColors: [String] = []
    @Published var selectedSeasons: Set<Season> = []
    @Published var selectedOccasions: Set<Occasion> = []
    @Published var brand: String = ""
    @Published var notes: String = ""
    @Published var isProcessing = false
    @Published var error: Error?
    @Published var useBackgroundRemoval = false  // Add this - default to false
    
    private let visionService: VisionService
    private let userId: String
    
    init(visionService: VisionService, userId: String) {
        self.visionService = visionService
        self.userId = userId
    }
    
    func processImage(_ image: UIImage) async {
        isProcessing = true
        capturedImage = image
        
        do {
            var imageToProcess = image
            
            // 1. Remove background ONLY if toggle is on
            if useBackgroundRemoval {
                let processed = try await visionService.removeBackground(from: image)
                processedImage = processed
                imageToProcess = processed
            } else {
                // Use original image directly
                processedImage = image
            }
            
            // 2. Detect colors from the processed/original image
            detectedColors = try await visionService.detectColors(in: imageToProcess)
            
            // 3. Classify category
            let suggestedCategory = try await visionService.classifyClothing(imageToProcess)
            category = suggestedCategory
            
        } catch {
            self.error = error
            // Fall back to original image if processing fails
            processedImage = image
            
            // Try to detect colors from original if processing failed
            if let colors = try? await visionService.detectColors(in: image) {
                detectedColors = colors
            }
        }
        
        isProcessing = false
    }
    
    func createItem() -> ClothingItem {
        ClothingItem(
            id: UUID().uuidString,
            userId: userId,
            imageURL: "", // Will be set after upload
            thumbnailURL: nil,
            category: category,
            colors: detectedColors,
            brand: brand.isEmpty ? nil : brand,
            season: Array(selectedSeasons),
            occasion: Array(selectedOccasions),
            notes: notes.isEmpty ? nil : notes,
            dateAdded: Date(),
            wearCount: 0,
            lastWornDate: nil,
            isFavorite: false,
            metadata: ItemMetadata()
        )
    }
    
    func reset() {
        capturedImage = nil
        processedImage = nil
        category = .top
        detectedColors = []
        selectedSeasons = []
        selectedOccasions = []
        brand = ""
        notes = ""
        error = nil
    }
}
