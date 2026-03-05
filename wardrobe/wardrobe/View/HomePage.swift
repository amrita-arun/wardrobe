//
//  HomePage.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//


import SwiftUI

struct HomePage: View {
    @ObservedObject var viewModel: SwipeFeedViewModel
    @StateObject private var weatherManager = WeatherManager()
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    
    // In HomePage body:

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 250/255, green: 250/255, blue: 248/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with date
                    headerSection
                    
                    // Weather widget
                    weatherWidget
                        .padding(.horizontal, 20)
                        .padding(.top, 8)  // Reduced from 12
                    
                    //Spacer(minLength: 4)  // Reduced from 8
                    
                    // Main content
                    if viewModel.isGenerating && viewModel.outfitQueue.isEmpty {
                        loadingView
                    } else if viewModel.currentIndex >= viewModel.outfitQueue.count {
                        noMoreOutfitsView
                    } else if viewModel.hasMoreOutfits {
                        swipeableCardStack
                           // .padding(.top, 15)
                    } else {
                        emptyStateView
                    }
                    
                    //Spacer(minLength: 4)  // Reduced from 8
                    
                    // Action buttons at bottom
                    if viewModel.hasMoreOutfits {
                        actionButtons
                            .padding(.horizontal, 20)
                            .padding(.top, 15)
                            .padding(.bottom, 16)  // Reduced from 20
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await weatherManager.fetchWeather()
            await viewModel.loadExistingOutfits()
            await viewModel.generateOutfits(temperature: weatherManager.temperature)
        }
    }

    // Add this view:
    private var noMoreOutfitsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
            
            Text("You've seen all outfits!")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            Text("Come back tomorrow for fresh suggestions, or add more items")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    viewModel.currentIndex = 0
                    viewModel.shownOutfitIds.removeAll()
                    viewModel.outfitQueue.removeAll()
                    // Reload existing outfits before generating
                    await viewModel.loadExistingOutfits()
                    await viewModel.generateOutfits()
                }
            } label: {
                Text("Generate More")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color(red: 168/255, green: 181/255, blue: 163/255))
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {  // Reduced from 4
            Text(Date().formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 13, weight: .medium))  // Reduced from 14
                .foregroundColor(.gray)
            
            Text(Date().formatted(.dateTime.month(.wide).day()))
                .font(.system(size: 24, weight: .semibold))  // Reduced from 28
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)  // Reduced from 60
    }
    
    // MARK: - Weather Widget
    
    private var weatherWidget: some View {
        let color = weatherManager.getWeatherColor()
        
        return HStack(spacing: 10) {
            Image(systemName: weatherManager.getWeatherIcon())
                .font(.system(size: 20))
                .foregroundColor(Color(red: color.red/255, green: color.green/255, blue: color.blue/255))
            
            VStack(alignment: .leading, spacing: 1) {
                if weatherManager.isLoading {
                    Text("Loading weather...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                } else if let temp = weatherManager.temperature, let condition = weatherManager.condition {
                    Text("\(temp)°F, \(condition)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    
                    if let recommendation = weatherManager.recommendation {
                        Text("Good for: \(recommendation)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("65°F, Partly Cloudy")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    Text("Good for: Light layers")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(red: 245/255, green: 241/255, blue: 237/255))
        .cornerRadius(12)
    }
    
    // MARK: - Swipeable Card Stack
    
    // In swipeableCardStack:

    private var swipeableCardStack: some View {
        ZStack {
            ForEach(Array(viewModel.visibleOutfits.enumerated()), id: \.element.id) { index, outfit in
                OutfitCardWithFetch(outfit: outfit, clothingRepo: ClothingRepository())
                    .frame(width: UIScreen.main.bounds.width - 40, height: 420)  // Reduced from 480
                    .offset(y: CGFloat(index * 8))
                    .scaleEffect(1 - (CGFloat(index) * 0.03))
                    .opacity(1 - (Double(index) * 0.2))
                    .zIndex(Double(viewModel.visibleOutfits.count - index))
                    .offset(index == 0 ? dragOffset : .zero)
                    .rotationEffect(index == 0 ? .degrees(dragRotation) : .zero)
                    .simultaneousGesture(
                        index == 0 ? dragGesture : nil
                    )
                    .overlay(
                        index == 0 ? swipeOverlay : nil
                    )
            }
        }
        .padding(.top, 16)
        .animation(.spring(response: 0.3), value: viewModel.currentIndex)
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)  // Add minimum distance
            .onChanged { value in
                // Only allow horizontal or strong vertical drags
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)
                
                // Prioritize horizontal swipes
                if horizontalAmount > verticalAmount || verticalAmount > 100 {
                    dragOffset = value.translation
                    dragRotation = Double(value.translation.width / 20)
                }
            }
            .onEnded { value in
                let swipeThreshold: CGFloat = 100
                
                if value.translation.width > swipeThreshold {
                    // Swipe right - LIKE
                    swipeRight()
                } else if value.translation.width < -swipeThreshold {
                    // Swipe left - DISLIKE
                    swipeLeft()
                } else if value.translation.height < -swipeThreshold {
                    // Swipe up - SUPER LIKE (wear today)
                    swipeUp()
                } else {
                    // Return to center
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                        dragRotation = 0
                    }
                }
            }
    }
    
    // MARK: - Swipe Actions
    

    private func swipeRight() {
        guard let outfit = viewModel.currentOutfit else { return }
        
        withAnimation(.spring(response: 0.3)) {
            dragOffset = CGSize(width: 500, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                await viewModel.handleSwipe(.like, for: outfit)
            }
            
            // Reset drag state AFTER updating index
            withAnimation {
                dragOffset = .zero
                dragRotation = 0
            }
        }
    }

    private func swipeLeft() {
        guard let outfit = viewModel.currentOutfit else { return }
        
        withAnimation(.spring(response: 0.3)) {
            dragOffset = CGSize(width: -500, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                await viewModel.handleSwipe(.dislike, for: outfit)
            }
            
            withAnimation {
                dragOffset = .zero
                dragRotation = 0
            }
        }
    }

    private func swipeUp() {
        guard let outfit = viewModel.currentOutfit else { return }
        
        withAnimation(.spring(response: 0.3)) {
            dragOffset = CGSize(width: 0, height: -500)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                await viewModel.handleSwipe(.superLike, for: outfit)
            }
            
            withAnimation {
                dragOffset = .zero
                dragRotation = 0
            }
        }
    }
    
    // MARK: - Swipe Overlay
    
    private var swipeOverlay: some View {
        ZStack {
            // Like overlay (right swipe)
            if dragOffset.width > 50 {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.3))
                    .overlay(
                        Text("LIKE")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                    )
            }
            
            // Dislike overlay (left swipe)
            if dragOffset.width < -50 {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.3))
                    .overlay(
                        Text("PASS")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.red)
                    )
            }
            
            // Super like overlay (up swipe)
            if dragOffset.height < -50 {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#A8B5A3").opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: "#A8B5A3"))
                            Text("WEARING TODAY!")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "#A8B5A3"))
                        }
                    )
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 20) {  // Reduced from 24
            // Dislike button
            Button {
                swipeLeft()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .semibold))  // Reduced from 28
                    .foregroundColor(.red)
                    .frame(width: 56, height: 56)  // Reduced from 64
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            }
            
            // Super like button
            Button {
                swipeUp()
            } label: {
                Image(systemName: "star.fill")
                    .font(.system(size: 24, weight: .semibold))  // Reduced from 28
                    .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                    .frame(width: 64, height: 64)  // Reduced from 72
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            }
            
            // Like button
            Button {
                swipeRight()
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24, weight: .semibold))  // Reduced from 28
                    .foregroundColor(.green)
                    .frame(width: 56, height: 56)  // Reduced from 64
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            }
        }
    }

    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "#A8B5A3"))
            
            Text("Generating your outfits...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#A8B5A3"))
            
            Text("No More Outfits")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "#2D2D2D"))
            
            Text("You've seen all of today's suggestions")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await viewModel.generateOutfits()
                }
            } label: {
                Text("Generate More")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#A8B5A3"))
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func getItems(for outfit: Outfit) -> [ClothingItem] {
            // Use the shared clothingRepo to fetch items
            return viewModel.getItems(for: outfit)
    }
    
    

}

// MARK: - Outfit Card Component

struct OutfitCard: View {
    let outfit: Outfit
    let items: [ClothingItem]
    
    var body: some View {
        VStack(spacing: 0) {
            // 2x2 Grid of clothing items
            let gridSize = (UIScreen.main.bounds.width - 40 - 32 - 12) / 2  // card width - padding - spacing
            
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
            
            // Tags and info at bottom
            VStack(alignment: .leading, spacing: 6) {
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

struct OutfitCardWithFetch: View {
    let outfit: Outfit
    let clothingRepo: ClothingRepository
    @State private var items: [ClothingItem] = []
    @State private var isLoading = true
    
    var body: some View {
        OutfitCard(outfit: outfit, items: items)
            .task {
                await loadItems()
            }
    }
    
    private func loadItems() async {
        for itemId in outfit.items {
            if let item = try? await clothingRepo.fetchItem(id: itemId) {
                items.append(item)
            }
        }
        isLoading = false
    }
}

// MARK: - SwipeFeedViewModel Extension

extension SwipeFeedViewModel {
    var visibleOutfits: [Outfit] {
        guard currentIndex < outfitQueue.count else {
            return []
        }
        let endIndex = min(currentIndex + 3, outfitQueue.count)
        return Array(outfitQueue[currentIndex..<endIndex])
    }
}
