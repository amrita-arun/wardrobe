//
//  StatsPage.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI
import Charts

struct StatsPage: View {
    @ObservedObject var viewModel: StatsViewModel
    @State private var selectedTimeRange: TimeRange = .thisMonth
    @State private var showingProfile = false  // Add this
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 250/255, green: 250/255, blue: 248/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Time range picker
                    timeRangePicker
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.totalOutfits == 0 {
                        emptyStateView
                    } else {
                        statsContent
                    }
                }
            }
            .navigationBarHidden(false)  // Change to false
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
        .task {
            await viewModel.loadStats(timeRange: selectedTimeRange)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your Insights")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            Text("Wardrobe analytics")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        
    }
    
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        Menu {
            ForEach([TimeRange.thisWeek, .thisMonth, .thisYear, .allTime], id: \.self) { range in
                Button {
                    selectedTimeRange = range
                    Task {
                        await viewModel.loadStats(timeRange: range)
                    }
                } label: {
                    HStack {
                        Text(range.displayName)
                        if selectedTimeRange == range {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedTimeRange.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                summaryCards
                
                // Most worn item
                if let mostWorn = viewModel.mostWornItem {
                    mostWornCard(item: mostWorn)
                }
                
                // Unworn items warning
                if viewModel.unwornCount > 0 {
                    unwornItemsCard
                }
                
                // Wear frequency chart
                if !viewModel.wearFrequencyByDay.isEmpty {
                    wearFrequencyChart
                }
                
                // Color distribution
                if !viewModel.colorDistribution.isEmpty {
                    colorDistributionSection
                }
                
                // Category breakdown
                categoryBreakdownSection
            }
            .padding(20)
            .padding(.bottom, 100) // Space for nav bar
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        HStack(spacing: 12) {
            StatSummaryCard(
                icon: "tshirt.fill",
                value: "\(viewModel.totalItems)",
                label: "Total Items",
                color: Color(red: 168/255, green: 181/255, blue: 163/255)
            )
            
            StatSummaryCard(
                icon: "checkmark.circle.fill",
                value: "\(viewModel.totalOutfits)",
                label: "Outfits Worn",
                color: .green
            )
        }
    }
    
    // MARK: - Most Worn Card
    
    private func mostWornCard(item: ClothingItem) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Most Worn Item")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                
                Spacer()
                
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)
            }
            .padding(16)
            
            Divider()
            
            // Item info
            HStack(spacing: 16) {
                // Item image
                Group {
                    if !item.imageURL.isEmpty {
                        AsyncImage(url: URL(string: item.imageURL)) { phase in
                            switch phase {
                            case .empty:
                                itemPlaceholder(category: item.category)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                itemPlaceholder(category: item.category)
                            @unknown default:
                                itemPlaceholder(category: item.category)
                            }
                        }
                    } else {
                        itemPlaceholder(category: item.category)
                    }
                }
                .frame(width: 80, height: 80)
                .background(Color(red: 245/255, green: 241/255, blue: 237/255))
                .cornerRadius(8)
                .clipped()
                
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.category.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    
                    if let brand = item.brand {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 12))
                            Text("\(item.wearCount) wears")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.gray)
                        
                        if let lastWorn = item.lastWornDate {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(lastWorn.formatted(.relative(presentation: .named)))
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Unworn Items Card
    
    private var unwornItemsCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.unwornCount) items not worn")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                
                Text("in 90+ days")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Wear Frequency Chart
    
    private var wearFrequencyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wear Frequency")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(sortedDaysOfWeek, id: \.self) { day in
                        BarMark(
                            x: .value("Day", shortDay(day)),
                            y: .value("Count", viewModel.wearFrequencyByDay[day] ?? 0)
                        )
                        .foregroundStyle(Color(red: 168/255, green: 181/255, blue: 163/255))
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                simpleBarChart
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var simpleBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedDaysOfWeek, id: \.self) { day in
                HStack {
                    Text(shortDay(day))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .leading)
                    
                    let count = viewModel.wearFrequencyByDay[day] ?? 0
                    let maxCount = viewModel.wearFrequencyByDay.values.max() ?? 1
                    let width = CGFloat(count) / CGFloat(maxCount)
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 168/255, green: 181/255, blue: 163/255))
                            .frame(width: geometry.size.width * width)
                    }
                    .frame(height: 20)
                    
                    Text("\(count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                        .frame(width: 30)
                }
            }
        }
    }
    
    private var sortedDaysOfWeek: [String] {
        let order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return order.filter { viewModel.wearFrequencyByDay.keys.contains($0) }
    }
    
    private func shortDay(_ day: String) -> String {
        String(day.prefix(3))
    }
    
    // MARK: - Color Distribution
    
    private var colorDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Color Palette")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            let sortedColors = viewModel.colorDistribution.sorted { $0.value > $1.value }.prefix(5)
            let totalWears = sortedColors.reduce(0) { $0 + $1.value }
            
            VStack(spacing: 12) {
                ForEach(Array(sortedColors), id: \.key) { color, count in
                    let percentage = totalWears > 0 ? Int((Double(count) / Double(totalWears)) * 100) : 0
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(colorName(for: color))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                            
                            Text("\(count) wears")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("\(percentage)%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            VStack(spacing: 12) {
                ForEach(viewModel.categoryBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                    HStack {
                        Image(systemName: iconForCategory(category))
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                            .frame(width: 24)
                        
                        Text(category.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                    
                    if category != viewModel.categoryBreakdown.keys.sorted(by: {
                        viewModel.categoryBreakdown[$0]! > viewModel.categoryBreakdown[$1]!
                    }).last {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(red: 168/255, green: 181/255, blue: 163/255))
            
            Text("Loading insights...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255).opacity(0.5))
            
            Text("No Data Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            Text("Start wearing outfits to see your stats")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func itemPlaceholder(category: ClothingCategory) -> some View {
        VStack(spacing: 6) {
            Image(systemName: iconForCategory(category))
                .font(.system(size: 28))
                .foregroundColor(.gray.opacity(0.3))
        }
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
    
    private func colorName(for hex: String) -> String {
        // Simple color naming based on hex
        let common: [String: String] = [
            "#000000": "Black",
            "#FFFFFF": "White",
            "#808080": "Gray",
            "#FF0000": "Red",
            "#0000FF": "Blue",
            "#00FF00": "Green",
            "#FFFF00": "Yellow",
            "#FFA500": "Orange",
            "#800080": "Purple",
            "#FFC0CB": "Pink",
            "#A52A2A": "Brown",
            "#000080": "Navy"
        ]
        
        return common[hex.uppercased()] ?? "Color"
    }
}

// MARK: - Stat Summary Card

struct StatSummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - StatsViewModel Updates

extension StatsViewModel {
    var totalItems: Int {
        categoryBreakdown.values.reduce(0, +)
    }
    
    var categoryBreakdown: [ClothingCategory: Int] {
        Dictionary(grouping: items) { $0.category }
            .mapValues { $0.count }
    }
}

