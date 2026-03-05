//
//  ItemDetailViewModel.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/24/25.
//

import Foundation

@MainActor
class ItemDetailViewModel: ObservableObject {
    @Published var item: ClothingItem
    @Published var error: Error?
    
    let repository: ClothingRepository
    private let userId: String
    
    init(item: ClothingItem, repository: ClothingRepository, userId: String) {
        self.item = item
        self.repository = repository
        self.userId = userId
    }
    
    func toggleFavorite() async {
        item.isFavorite.toggle()
        
        do {
            try await repository.updateItem(item)
        } catch {
            self.error = error
            // Revert on error
            item.isFavorite.toggle()
        }
    }
    
    func updateItem(_ updatedItem: ClothingItem) async {
        do {
            try await repository.updateItem(updatedItem)
            self.item = updatedItem
        } catch {
            self.error = error
        }
    }
    
    func deleteItem() async {
        guard let id = item.id else { return }
        
        do {
            try await repository.deleteItem(id: id)
        } catch {
            self.error = error
        }
    }
}
