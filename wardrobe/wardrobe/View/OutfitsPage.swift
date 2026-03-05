//
//  OutfitsPage.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI

struct OutfitsPage: View {
    @ObservedObject var viewModel: OutfitsViewModel
    @State private var selectedFilter: OutfitFilter = .all
    @State private var showingFilterSheet = false
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - use a solid color first to test
                Color(red: 250/255, green: 250/255, blue: 248/255) // #FAFAF8
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Filter tabs
                    filterTabs
                        .padding(.top, 16)
                    
                    // Content
                    if viewModel.isLoading && viewModel.outfits.isEmpty {
                        loadingView
                    } else if viewModel.filteredOutfits.isEmpty {
                        emptyStateView
                    } else {
                        outfitsList
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadOutfits()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My Outfits")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            Text("\(viewModel.filteredOutfits.count) saved")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 30)
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(OutfitFilter.allCases, id: \.self) { filter in
                    FilterTabButton(
                        title: filter.title,
                        count: viewModel.getCount(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        viewModel.filterOutfits(by: filter)
                    }
                }
            }
            .padding(.horizontal, 36)
        }
        .padding(.horizontal, -20)
    }
    
    // MARK: - Outfits List
    
    private var outfitsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredOutfits) { outfit in
                    SavedOutfitCard(
                        outfit: outfit,
                        items: viewModel.getItems(for: outfit)
                    )
                    .onTapGesture {
                        // TODO: Navigate to outfit detail
                    }
                    .contextMenu {
                        Button {
                            Task {
                                await viewModel.toggleFavorite(outfit)
                            }
                        } label: {
                            Label(
                                outfit.isFavorite ? "Unfavorite" : "Favorite",
                                systemImage: outfit.isFavorite ? "heart.fill" : "heart"
                            )
                        }
                        
                        Button {
                            Task {
                                await viewModel.markAsWornToday(outfit)
                            }
                        } label: {
                            Label("Wore This Today", systemImage: "checkmark.circle")
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteOutfit(outfit)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 100) // Space for nav bar
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "#A8B5A3"))
            
            Text("Loading your outfits...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#A8B5A3").opacity(0.5))
            
            Text(emptyStateTitle)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            Text(emptyStateMessage)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "folder"
        case .favorites: return "heart"
        case .recent: return "clock"
        case .unworn: return "sparkles"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Saved Outfits"
        case .favorites: return "No Favorites"
        case .recent: return "No Recent Outfits"
        case .unworn: return "All Caught Up!"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Outfits you like will be saved here"
        case .favorites: return "Heart outfits to save them as favorites"
        case .recent: return "Outfits you've worn will appear here"
        case .unworn: return "You've tried all your saved outfits"
        }
    }
}

// MARK: - Filter Tab Button

struct FilterTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                    if count > 0 {
                        Text("(\(count))")
                            .foregroundColor(.gray)
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "#2D2D2D") : .gray)
                
                // Underline indicator
                Rectangle()
                    .fill(isSelected ? Color(hex: "#A8B5A3") : Color.clear)
                    .frame(height: 2)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Saved Outfit Card

// Replace the entire SavedOutfitCard in OutfitsPage.swift

struct SavedOutfitCard: View {
    let outfit: Outfit
    let items: [ClothingItem]
    
    var body: some View {
        VStack(spacing: 0) {
            // 2x2 Grid of clothing items
            let gridSize = (UIScreen.main.bounds.width - 40 - 32 - 12) / 2
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    itemThumbnail(category: .top)
                        .frame(width: gridSize, height: gridSize)
                    itemThumbnail(category: .outerwear)
                        .frame(width: gridSize, height: gridSize)
                }
                
                HStack(spacing: 12) {
                    itemThumbnail(category: .bottom)
                        .frame(width: gridSize, height: gridSize)
                    itemThumbnail(category: .shoes)
                        .frame(width: gridSize, height: gridSize)
                }
            }
            .padding(16)
            
            // Info section at bottom
            VStack(alignment: .leading, spacing: 8) {
                // Top row: Generation info + Favorite
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(outfit.generatedBy == .algorithm ? "AI Generated" : "Created")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text(outfit.createdDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if outfit.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                }
                
                // Occasion tags
                if !outfit.occasions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(outfit.occasions, id: \.self) { occasion in
                                Text(occasion.rawValue.capitalized)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 168/255, green: 181/255, blue: 163/255).opacity(0.15))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Worn status
                HStack(spacing: 4) {
                    if outfit.wornDates.isEmpty {
                        Image(systemName: "circle")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                        Text("Never worn")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("Worn \(outfit.wornDates.count)x")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        
                        if let lastWorn = outfit.wornDates.max() {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(lastWorn.formatted(.relative(presentation: .named)))
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Match score
                if let score = outfit.score {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text("Match Score: \(Int(score))%")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 12, y: 6)
    }
    
    private func itemThumbnail(category: ClothingCategory) -> some View {
        let item = items.first(where: { $0.category == category })
        
        return Group {
            if let item = item, !item.imageURL.isEmpty {
                AsyncImage(url: URL(string: item.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView(for: category)
                    @unknown default:
                        placeholderView(for: category)
                    }
                }
            } else {
                placeholderView(for: category)
            }
        }
        .background(Color(red: 245/255, green: 241/255, blue: 237/255))
        .cornerRadius(12)
        .clipped()
    }
    
    private func placeholderView(for category: ClothingCategory) -> some View {
        VStack(spacing: 8) {
            Image(systemName: iconForCategory(category))
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.3))
            
            Text(category.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
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
// MARK: - OutfitsViewModel

@MainActor
class OutfitsViewModel: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var filteredOutfits: [Outfit] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repository: OutfitRepository
    private let clothingRepo: ClothingRepository
    private let userId: String
    private var itemsCache: [String: ClothingItem] = [:]
    
    init(repository: OutfitRepository, userId: String) {
        self.repository = repository
        self.clothingRepo = ClothingRepository()
        self.userId = userId
    }
    
    func loadOutfits() async {
        isLoading = true
        
        do {
            outfits = try await repository.fetchOutfits(userId: userId)
            filteredOutfits = outfits
            
            // Preload items for all outfits
            await loadAllItems()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func loadAllItems() async {
        let allItemIds = Set(outfits.flatMap { $0.items })
        
        for itemId in allItemIds {
            if itemsCache[itemId] == nil {
                if let item = try? await clothingRepo.fetchItem(id: itemId) {
                    itemsCache[itemId] = item
                }
            }
        }
    }
    
    func filterOutfits(by filter: OutfitFilter) {
        switch filter {
        case .all:
            filteredOutfits = outfits
            
        case .favorites:
            filteredOutfits = outfits.filter { $0.isFavorite }
            
        case .recent:
            filteredOutfits = outfits
                .filter { !$0.wornDates.isEmpty }
                .sorted { ($0.wornDates.max() ?? .distantPast) > ($1.wornDates.max() ?? .distantPast) }
            
        case .unworn:
            filteredOutfits = outfits.filter { $0.wornDates.isEmpty }
        }
    }
    
    func getCount(for filter: OutfitFilter) -> Int {
        switch filter {
        case .all:
            return outfits.count
        case .favorites:
            return outfits.filter { $0.isFavorite }.count
        case .recent:
            return outfits.filter { !$0.wornDates.isEmpty }.count
        case .unworn:
            return outfits.filter { $0.wornDates.isEmpty }.count
        }
    }
    
    func getItems(for outfit: Outfit) -> [ClothingItem] {
        outfit.items.compactMap { itemsCache[$0] }
    }
    
    func toggleFavorite(_ outfit: Outfit) async {
        var updated = outfit
        updated.isFavorite.toggle()
        
        do {
            try await repository.updateOutfit(updated)
            
            if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
                outfits[index] = updated
            }
            if let index = filteredOutfits.firstIndex(where: { $0.id == outfit.id }) {
                filteredOutfits[index] = updated
            }
        } catch {
            self.error = error
        }
    }
    
    func markAsWornToday(_ outfit: Outfit) async {
        let wearLog = WearLog(
            id: UUID().uuidString,
            userId: userId,
            outfitId: outfit.id,
            itemIds: outfit.items,
            date: Date(),
            mood: nil,
            notes: nil,
            weather: nil
        )
        
        do {
            try await repository.saveWearLog(wearLog)
            
            // Update local outfit with new worn date
            var updated = outfit
            updated.wornDates.append(Date())
            
            if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
                outfits[index] = updated
            }
            if let index = filteredOutfits.firstIndex(where: { $0.id == outfit.id }) {
                filteredOutfits[index] = updated
            }
        } catch {
            self.error = error
        }
    }
    
    func deleteOutfit(_ outfit: Outfit) async {
        do {
            try await repository.deleteOutfit(id: outfit.id)
            
            outfits.removeAll { $0.id == outfit.id }
            filteredOutfits.removeAll { $0.id == outfit.id }
        } catch {
            self.error = error
        }
    }
}

// MARK: - Outfit Filter Enum

enum OutfitFilter: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case recent = "Recently Worn"
    case unworn = "Never Worn"
    
    var title: String { rawValue }
}


