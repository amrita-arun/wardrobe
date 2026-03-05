//
//  ClosetViewModel.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import Foundation
import UIKit
// MARK: - Closet ViewModel

@MainActor
class ClosetViewModel: ObservableObject {
    @Published var items: [ClothingItem] = []
    @Published var filteredItems: [ClothingItem] = []
    @Published var selectedCategory: ClothingCategory?
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dateAdded
    @Published var isLoading = false
    @Published var error: Error?
    
    let repository: ClothingRepository
    private let storageService: StorageService
    let userId: String  // ← Add this
    
    init(repository: ClothingRepository, storageService: StorageService, userId: String) {
        self.repository = repository
        self.storageService = storageService
        self.userId = userId  // ← Store it
    }
    
    
    func loadItems() async {
        isLoading = true
        do {
            items = try await repository.fetchAllItems(userId: userId)  // ← Use it here
            applyFilters()
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    func addItem(_ item: ClothingItem, image: UIImage) async throws {
        // Get the unwrapped ID
            guard let itemId = item.id else {
                throw NSError(domain: "ClosetViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item ID is nil"])
            }
            
            // 1. Upload image to Firebase Storage
            // Just pass the item ID, not "clothing/itemId"
            let imageURL = try await storageService.uploadImage(image, path: itemId, userId: userId)
            
            // 2. Create item with imageURL
            var newItem = item
            newItem.imageURL = imageURL
            
            // 3. Save to Firestore
            try await repository.saveItem(newItem)
            
            // 4. Update local state
            items.append(newItem)
            applyFilters()
    }
    
    func deleteItem(_ item: ClothingItem) async throws {
        try await repository.deleteItem(id: item.id ?? "")
        try await storageService.deleteImage(at: item.imageURL)
        items.removeAll { $0.id == item.id }
        applyFilters()
    }
    
    func updateItem(_ item: ClothingItem) async throws {
        try await repository.updateItem(item)
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            applyFilters()
        }
    }
    
    
}
// ViewModels/ClosetViewModel.swift

extension ClosetViewModel {
    enum SortOption: CaseIterable {
        case dateAdded, lastWorn, wearCount, alphabetical
        
        var displayName: String {
            switch self {
            case .dateAdded: return "Recently Added"
            case .lastWorn: return "Least Recently Worn"
            case .wearCount: return "Most Worn"
            case .alphabetical: return "Alphabetical"
            }
        }
    }
    
    func toggleFavorite(_ item: ClothingItem) async {
        var updatedItem = item
        updatedItem.isFavorite.toggle()
        
        do {
            try await updateItem(updatedItem)
        } catch {
            self.error = error
        }
    }
    
    func applyFilters() {
        var filtered = items
        
        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.brand?.localizedCaseInsensitiveContains(searchText) ?? false ||
                item.notes?.localizedCaseInsensitiveContains(searchText) ?? false ||
                item.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort
        switch sortOption {
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        case .lastWorn:
            filtered.sort {
                let days1 = $0.daysSinceWorn ?? Int.max
                let days2 = $1.daysSinceWorn ?? Int.max
                return days1 > days2
            }
        case .wearCount:
            filtered.sort { $0.wearCount > $1.wearCount }
        case .alphabetical:
            filtered.sort { ($0.brand ?? "") < ($1.brand ?? "") }
        }
        
        filteredItems = filtered
    }
}
