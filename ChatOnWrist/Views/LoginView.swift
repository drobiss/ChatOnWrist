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
                // For testing, just set authenticated to true
                authService.isAuthenticated = true
                authService.userAccessToken = "test_token"
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(height: 50)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationService())
}
