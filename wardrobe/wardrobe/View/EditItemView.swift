//
//  EditItemView.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/24/25.
//

import SwiftUI

struct EditItemView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ItemDetailViewModel
    
    @State private var category: ClothingCategory
    @State private var brand: String
    @State private var selectedSeasons: Set<Season>
    @State private var selectedOccasions: Set<Occasion>
    @State private var notes: String
    @State private var isSaving = false
    
    init(viewModel: ItemDetailViewModel) {
        self.viewModel = viewModel
        _category = State(initialValue: viewModel.item.category)
        _brand = State(initialValue: viewModel.item.brand ?? "")
        _selectedSeasons = State(initialValue: Set(viewModel.item.season))
        _selectedOccasions = State(initialValue: Set(viewModel.item.occasion))
        _notes = State(initialValue: viewModel.item.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category
                    categorySection
                    
                    // Brand
                    brandSection
                    
                    // Seasons
                    seasonsSection
                    
                    // Occasions
                    occasionsSection
                    
                    // Notes
                    notesSection
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(red: 250/255, green: 250/255, blue: 248/255))
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            Picker("Category", selection: $category) {
                ForEach(ClothingCategory.allCases, id: \.self) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var brandSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brand (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            TextField("Enter brand", text: $brand)
                .font(.system(size: 16))
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
        }
    }
    
    private var seasonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seasons")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            FlowLayout(spacing: 8) {
                ForEach(Season.allCases, id: \.self) { season in
                    SelectableChip(
                        title: season.rawValue.capitalized,
                        isSelected: selectedSeasons.contains(season)
                    ) {
                        if selectedSeasons.contains(season) {
                            selectedSeasons.remove(season)
                        } else {
                            selectedSeasons.insert(season)
                        }
                    }
                }
            }
        }
    }
    
    private var occasionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Occasions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            FlowLayout(spacing: 8) {
                ForEach(Occasion.allCases, id: \.self) { occasion in
                    SelectableChip(
                        title: occasion.rawValue.capitalized,
                        isSelected: selectedOccasions.contains(occasion)
                    ) {
                        if selectedOccasions.contains(occasion) {
                            selectedOccasions.remove(occasion)
                        } else {
                            selectedOccasions.insert(occasion)
                        }
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            TextEditor(text: $notes)
                .font(.system(size: 16))
                .frame(height: 100)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private func saveChanges() async {
        isSaving = true
        
        var updatedItem = viewModel.item
        updatedItem.category = category
        updatedItem.brand = brand.isEmpty ? nil : brand
        updatedItem.season = Array(selectedSeasons)
        updatedItem.occasion = Array(selectedOccasions)
        updatedItem.notes = notes.isEmpty ? nil : notes
        
        await viewModel.updateItem(updatedItem)
        
        isSaving = false
        dismiss()
    }
}
