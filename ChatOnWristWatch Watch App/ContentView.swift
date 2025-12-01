//
//  ContentView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var conversationStore = ConversationStore()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var watchConnectivity = WatchConnectivityService()
    @StateObject private var syncService = ConversationSyncService.shared
    
    @Binding var shouldStartDictation: Bool
    
    var body: some View {
        if authService.isAuthenticated {
            Group {
                if authService.deviceToken == nil {
                    PairingView()
                        .environmentObject(authService)
                } else {
                    WatchHomeView(shouldStartDictation: $shouldStartDictation)
                        .environmentObject(conversationStore)
                        .environmentObject(authService)
                        .environmentObject(watchConnectivity)
                        .environmentObject(syncService)
                }
            }
            .task {
                conversationStore.attach(modelContext: modelContext)
                syncService.configure(conversationStore: conversationStore)
                // Configure auth service to request token from iPhone if needed
                authService.configure(watchConnectivity: watchConnectivity)
                
                // Wait a bit for everything to initialize, then request conversations
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                // Request conversations from iPhone
                if watchConnectivity.isPhoneReachable {
                    print("⌚️ Requesting conversations from iPhone (from task)")
                    watchConnectivity.requestConversationFromiPhone()
                } else {
                    print("⌚️ iPhone not reachable yet, will try when it becomes reachable")
                }
            }
            .onChange(of: watchConnectivity.isPhoneReachable) { oldValue, newValue in
                // When iPhone becomes reachable, request conversations
                if newValue {
                    print("⌚️ iPhone reachability changed to \(newValue) - requesting conversations")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        watchConnectivity.requestConversationFromiPhone()
                    }
                }
            }
        } else {
            // Show message when not authenticated
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                
                Text("Not Signed In")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Sign in on iPhone")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .task {
                // Request token from iPhone
                authService.configure(watchConnectivity: watchConnectivity)
            }
        }
    }
}

#Preview {
    ContentView(shouldStartDictation: .constant(false))
}

// MARK: - Pairing UI

struct PairingView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var pairingCode: String = ""
    @State private var isPairing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Enter Pairing Code")
                .font(.headline)
            
            Text("Open the iPhone app → Settings → Generate Pairing Code. Enter it here to link the watch.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            TextField("123456", text: $pairingCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            Button(action: pair) {
                if isPairing {
                    ProgressView()
                } else {
                    Text("Pair Watch")
                        .font(.body.bold())
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPairing || pairingCode.count < 4)
        }
        .padding()
    }
    
    private func pair() {
        let code = pairingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        
        isPairing = true
        errorMessage = nil
        
        Task {
            let success = await authService.pairDevice(pairingCode: code)
            await MainActor.run {
                isPairing = false
                if !success {
                    errorMessage = "Pairing failed. Check the code and try again."
                }
            }
        }
    }
}
