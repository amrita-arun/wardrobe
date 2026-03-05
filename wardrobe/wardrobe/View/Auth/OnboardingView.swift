//
//  OnboardingView.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/23/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var showSignIn = false
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 250/255, green: 250/255, blue: 248/255)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon/Logo
                VStack(spacing: 16) {
                    Image(systemName: "hanger")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                    
                    Text("Wardrobe")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                }
                
                // Tagline
                VStack(spacing: 12) {
                    Text("Your closet, organized")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                    
                    Text("Never forget what you own.\nGet outfit suggestions based on what you haven't worn.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        showSignIn = true
                    } label: {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 168/255, green: 181/255, blue: 163/255))
                            .cornerRadius(12)
                    }
                    
                    Text("Free forever")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .fullScreenCover(isPresented: $showSignIn) {
            AuthenticationView()
        }
    }
}

#Preview {
    OnboardingView()
}
