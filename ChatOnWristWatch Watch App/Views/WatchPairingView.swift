//
//  WatchPairingView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct WatchPairingView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var pairingCode = ""
    @State private var isPairing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "applewatch")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Pair with iPhone")
                .font(.headline)
            
            Text("Enter the pairing code from your iPhone app")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Pairing Code", text: $pairingCode)
                .multilineTextAlignment(.center)
            
            Button(action: pairDevice) {
                HStack {
                    if isPairing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isPairing ? "Pairing..." : "Pair Device")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(pairingCode.isEmpty || isPairing)
            
            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .alert("Pairing Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func pairDevice() {
        Task {
            isPairing = true
            showError = false
            
            let success = await authService.pairDevice(pairingCode: pairingCode)
            
            await MainActor.run {
                isPairing = false
                
                if success {
                    print("Device paired successfully")
                } else {
                    errorMessage = authService.errorMessage ?? "Pairing failed. Please try again."
                    showError = true
                }
            }
        }
    }
}

#Preview {
    WatchPairingView()
        .environmentObject(AuthenticationService())
}
