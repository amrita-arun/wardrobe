//
//  NavBar.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/22/25.
//

import SwiftUI

struct NavBar: View {
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Image(systemName: tab.label.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selectedTab == tab ? Color.sageGreen : Color.darkGray)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
        
    }
}
