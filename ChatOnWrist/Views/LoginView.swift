//
//  LoginView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "applewatch")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("ChatOnWrist")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("AI Chat for Apple Watch")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Sign in with Apple") {
                print("Sign in button tapped!")
                authenticateWithApple()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(height: 50)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
    
    private func authenticateWithApple() {
        // For now, simulate successful authentication
        // In a real app, you'd use SignInWithAppleButton
        Task {
            await MainActor.run {
                authService.isAuthenticated = true
                authService.userAccessToken = "mock_user_token_\(UUID().uuidString)"
                authService.deviceToken = "mock_device_token_\(UUID().uuidString)"
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationService())
}
