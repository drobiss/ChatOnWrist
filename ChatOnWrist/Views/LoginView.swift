//
//  LoginView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

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
            .disabled(authService.isLoading)
            
            if authService.isLoading {
                ProgressView("Signing in...")
                    .padding(.top, 10)
            }
            
            if let errorMessage = authService.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func authenticateWithApple() {
        authService.signInWithApple()
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationService())
}
