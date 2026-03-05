//
//  ClosetPage.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI

struct ClosetPage: View {
    @ObservedObject var viewModel: ClosetViewModel
    @State private var showingAddItem = false
    @State private var showingFilterSheet = false
    @State private var selectedItem: ClothingItem?
    @State private var showingItemDetail = false
    
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#FAFAF8")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Search bar
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Filter chips
                    filterChips
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // Content
                    if viewModel.isLoading && viewModel.items.isEmpty {
                        loadingView
                    } else if viewModel.filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        itemsGrid
                    }
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 100) // Space for nav bar
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddItem) {
                AddItemView(
                    userId: viewModel.userId,  // TODO: Get from appViewModel
                    closetViewModel: viewModel
                )
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadItems()
        }
        .sheet(isPresented: $showingItemDetail) {
            if let item = selectedItem {
                ItemDetailView(viewModel: ItemDetailViewModel(
                    item: item,
                    repository: viewModel.repository,
                    userId: viewModel.userId
                ))
            }
        }
    }
    
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My Closet")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            Text("\(viewModel.filteredItems.count) items")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search your closet...", text: $viewModel.searchText)
                .font(.system(size: 16))
                .onChange(of: viewModel.searchText) { _ in
                    viewModel.applyFilters()
                }
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.applyFilters()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil,
                    count: viewModel.items.count
                ) {
                    viewModel.selectedCategory = nil
                    viewModel.applyFilters()
                }
                
                // Category filters
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    let count = viewModel.items.filter { $0.category == category }.count
                    
                    FilterChip(
                        title: category.displayName,
                        isSelected: viewModel.selectedCategory == category,
                        count: count
                    ) {
                        viewModel.selectedCategory = category
                        viewModel.applyFilters()
                    }
                }
                
                // Sort/Filter button
                Button {
                    showingFilterSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Sort")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#2D2D2D"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#2D2D2D"), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
    
    // MARK: - Items Grid
    
    // In ClosetPage's itemsGrid:

    private var itemsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(viewModel.filteredItems) { item in
                    ClothingItemCard(item: item)
                        .aspectRatio(1, contentMode: .fit)
                        .contentShape(Rectangle())  // Add this - makes entire area tappable
                        .onTapGesture {
                            selectedItem = item
                            showingItemDetail = true
                        }
                        .contextMenu {
                            Button {
                                Task {
                                    await viewModel.toggleFavorite(item)
                                }
                            } label: {
                                Label(
                                    item.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: item.isFavorite ? "heart.slash" : "heart"
                                )
                            }
                            
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await viewModel.deleteItem(item)
                                    } catch {
                                        print("Error")
                                    }
                                    
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button {
            showingAddItem = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color(hex: "#A8B5A3"))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "#A8B5A3"))
            
            Text("Loading your closet...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.searchText.isEmpty ? "hanger" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#A8B5A3").opacity(0.5))
            
            Text(viewModel.searchText.isEmpty ? "Your closet is empty" : "No items found")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            Text(viewModel.searchText.isEmpty ? "Start by adding your first item" : "Try adjusting your search or filters")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            if viewModel.searchText.isEmpty {
                Button {
                    showingAddItem = true
                } label: {
                    Text("Add Item")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#A8B5A3"))
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    
    init(title: String, isSelected: Bool, count: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.count = count
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                if let count = count, count > 0 {
                    Text("(\(count))")
                        .foregroundColor(.gray)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .white : Color(hex: "#2D2D2D"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "#A8B5A3") : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Clothing Item Card Component

struct ClothingItemCard: View {
    let item: ClothingItem
    
    var body: some View {
        VStack(spacing: 0) {
            // Image - takes full card, cropped to square
            ZStack(alignment: .bottomTrailing) {
                if !item.imageURL.isEmpty {
                    AsyncImage(url: URL(string: item.imageURL)) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Last worn badge - bottom right
                if let daysSince = item.daysSinceWorn {
                    Text(daysSince == 0 ? "Today" : "\(daysSince)d ago")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                        .padding(6)
                } else {
                    Text("Never worn")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(red: 168/255, green: 181/255, blue: 163/255))
                        .cornerRadius(4)
                        .padding(6)
                }
                
                // Favorite indicator - top right
                if item.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)  // Force square
            .background(Color(red: 245/255, green: 241/255, blue: 237/255))
            .cornerRadius(8)
            .clipped()
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }
    
    private var placeholderImage: some View {
        VStack(spacing: 8) {
            Image(systemName: iconForCategory(item.category))
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func iconForCategory(_ category: ClothingCategory) -> String {
        switch category {
        case .top: return "tshirt"
        case .bottom: return "minus"
        case .dress: return "figure.dress.line.vertical.figure"
        case .outerwear: return "cloud"
        case .shoes: return "shoe"
        case .accessory: return "bag"
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ClosetViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sort options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sort By")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D2D2D"))
                    
                    ForEach(ClosetViewModel.SortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                            viewModel.applyFilters()
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#2D2D2D"))
                                
                                Spacer()
                                
                                if viewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#A8B5A3"))
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        
                        if option != ClosetViewModel.SortOption.allCases.last {
                            Divider()
                        }
                    }
                }
                .padding(20)
                
                Spacer()
                
                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#A8B5A3"))
                        .cornerRadius(12)
                }
                .padding(20)
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(400)])
    }
}

// MARK: - Placeholder AddItemView
/*
struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Item Flow")
                    .font(.title)
                
                Text("Camera capture coming next!")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
 */
