//
//  AuthenticationView.swift
//  wardrobe
//
//  Created by Amrita Arun on 12/23/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AuthenticationView: View {
    @StateObject private var authService = AuthService()
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 250/255, green: 250/255, blue: 248/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                            
                            Text(isSignUp ? "Sign up to get started" : "Sign in to continue")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 60)
                        
                        // Email/Password Form
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                                
                                TextField("your@email.com", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .foregroundColor(.black)
                                    
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 45/255, green: 45/255, blue: 45/255))
                                
                                SecureField("••••••••", text: $password)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Sign In/Up Button
                        Button {
                            Task {
                                await handleEmailAuth()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 168/255, green: 181/255, blue: 163/255))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 32)
                        
                        // Apple Sign In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            Task {
                                await handleAppleSignIn(result)
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                        
                        // Toggle Sign Up/In
                        Button {
                            isSignUp.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(.gray)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundColor(Color(red: 168/255, green: 181/255, blue: 163/255))
                            }
                            .font(.system(size: 14))
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: authService.isAuthenticated) { isAuth in
                if isAuth {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Email Auth
    
    private func handleEmailAuth() async {
        isLoading = true
        
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In
    
    // In AuthenticationView.swift, replace the handleAppleSignIn function:

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Failed to get Apple ID token"
                showError = true
                return
            }
            
            // Use the correct credential method
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                accessToken: nil
            )
            
            do {
                try await authService.signInWithApple(credential: credential)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    AuthenticationView()
}
