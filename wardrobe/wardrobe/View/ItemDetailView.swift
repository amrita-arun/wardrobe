//
//  ItemDetailView.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/24/25.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ItemDetailViewModel
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Large image preview
                    imageSection
                    
                    // Item details
                    detailsSection
                    
                    // Wear history
                    wearHistorySection
                    
                    // Delete button
                    deleteButton
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(Color(red: 250/255, green: 250/255, blue: 248/255))
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
            .confirmationDialog("Delete Item", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteItem()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this item? This cannot be undone.")
            }
            .sheet(isPresented: $showEditSheet) {
                EditItemView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        VStack(spacing: 12) {
            if !viewModel.item.imageURL.isEmpty {
                AsyncImage(url: URL(string: viewModel.item.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 400)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
            
            // Favorite button
            Button {
                Task {
                    await viewModel.toggleFavorite()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.item.isFavorite ? "heart.fill" : "heart")
                    Text(viewModel.item.isFavorite ? "Favorited" : "Add to Favorites")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(viewModel.item.isFavorite ? .red : Color(red: 45/255, green: 45/255, blue: 45/255))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.item.isFavorite ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
    }
    
    private var placeholderImage: some View {
        VStack(spacing: 16) {
            Image(systemName: iconForCategory(viewModel.item.category))
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            Text(viewModel.item.category.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(height: 400)
        .frame(maxWidth: .infinity)
        .background(Color(red: 245/255, green: 241/255, blue: 237/255))
        .cornerRadius(16)
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            // Category
            detailRow(title: "Category", value: viewModel.item.category.displayName)
            
            Divider()
            
            // Brand
            if let brand = viewModel.item.brand {
                detailRow(title: "Brand", value: brand)
                Divider()
            }
            
            // Colors
            if !viewModel.item.colors.isEmpty {
                HStack {
                    Text("Colors")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ForEach(viewModel.item.colors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                Divider()
            }
            
            // Seasons
            if !viewModel.item.season.isEmpty {
                HStack(alignment: .top) {
                    Text("Seasons")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(viewModel.item.season, id: \.self) { season in
                            Text(season.rawValue.capitalized)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                Divider()
            }
            
            // Occasions
            if !viewModel.item.occasion.isEmpty {
                HStack(alignment: .top) {
                    Text("Occasions")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(viewModel.item.occasion, id: \.self) { occasion in
                            Text(occasion.rawValue.capitalized)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                Divider()
            }
            
            // Notes
            if let notes = viewModel.item.notes {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Divider()
            }
            
            // Date added
            detailRow(title: "Added", value: viewModel.item.dateAdded.formatted(date: .long, time: .omitted))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Wear History Section
    
    private var wearHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wear History")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(viewModel.item.wearCount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                    
                    Text("Times Worn")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    if let daysSince = viewModel.item.daysSinceWorn {
                        Text("\(daysSince)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                        
                        Text("Days Since Worn")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text("Never")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Text("Never Worn")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                if let lastWorn = viewModel.item.lastWornDate {
                    Divider()
                        .frame(height: 50)
                    
                    VStack(spacing: 4) {
                        Text(lastWorn.formatted(.dateTime.month().day()))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                        
                        Text("Last Worn")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Text("Delete Item")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 1.5)
                )
        }
    }
    
    // MARK: - Helpers
    
    private func iconForCategory(_ category: ClothingCategory) -> String {
        switch category {
        case .top: return "tshirt"
        case .bottom: return "minus"
        case .dress: return "figure.dress.line.vertical.figure"
        case .outerwear: return "cloud"
        case .shoes: return "shoe.fill"
        case .accessory: return "bag"
        }
    }
}

#Preview {
    ItemDetailView(viewModel: ItemDetailViewModel(
        item: ClothingItem(
            id: "test",
            userId: "test",
            imageURL: "",
            thumbnailURL: nil,
            category: .top,
            colors: ["#FF0000"],
            brand: "Test Brand",
            season: [.summer],
            occasion: [.casual],
            notes: "Test notes",
            dateAdded: Date(),
            wearCount: 5,
            lastWornDate: Date(),
            isFavorite: false,
            metadata: ItemMetadata()
        ),
        repository: ClothingRepository(),
        userId: "test"
    ))
}
