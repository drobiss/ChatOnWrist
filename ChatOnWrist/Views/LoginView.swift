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
        ZStack {
            // True black background with subtle glow
            Color.black.ignoresSafeArea()
            iOSPalette.backgroundGlow.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Icon
                Image(systemName: "applewatch")
                    .font(.system(size: 80))
                    .foregroundColor(iOSPalette.accent)
                    .padding(.bottom, 20)
                
                Text("ChatOnWrist")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(iOSPalette.textPrimary)
                
                Text("Your AI assistant on your wrist")
                    .font(.system(size: 16))
                    .foregroundColor(iOSPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Sign In Button
                Button(action: {
                    authService.signInWithApple()
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign In with Apple")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(iOSPalette.accent)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationService())
}
