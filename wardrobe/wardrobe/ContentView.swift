//
//  ContentView.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI

// ContentView.swift

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, closet, outfits, stats
    
    var id: String { rawValue }
    
    var label: (icon: String, title: String) {
        switch self {
        case .home: return ("house", "Today")
        case .closet: return ("cabinet", "Closet")
        case .outfits: return ("folder", "Outfits")
        case .stats: return ("chart.bar.xaxis", "Stats")
        }
    }
}

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            if authService.isAuthenticated, let userId = authService.currentUserId {
                MainAppView(userId: userId, selectedTab: $selectedTab)
            } else {
                OnboardingView()
            }
        }
        .environmentObject(authService)
    }
}

// Separate view to handle AppViewModel lifecycle
struct MainAppView: View {
    let userId: String
    @Binding var selectedTab: AppTab
    @StateObject private var appViewModel: AppViewModel
    
    init(userId: String, selectedTab: Binding<AppTab>) {
        self.userId = userId
        self._selectedTab = selectedTab
        self._appViewModel = StateObject(wrappedValue: AppViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case .home:
                    HomePage(viewModel: appViewModel.swipeFeedViewModel)
                case .closet:
                    ClosetPage(viewModel: appViewModel.closetViewModel)
                case .outfits:
                    OutfitsPage(viewModel: appViewModel.outfitsViewModel)
                case .stats:
                    StatsPage(viewModel: appViewModel.statsViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                Spacer()
                NavBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ContentView()
}
