//
//  SettingsView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var backendService = BackendService()
    
    @State private var showingBackendStatus = false
    @State private var showingLogoutAlert = false
    @State private var pairingCode: String?
    @State private var pairingExpires: String?
    @State private var isGeneratingCode = false
    @State private var pairingError: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Glassmorphism background
                Color.black
                    .ignoresSafeArea()
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                // User Section
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Signed in with Apple")
                                .font(.headline)
                            Text("User ID: \(authService.userAccessToken?.prefix(8) ?? "Not signed in")...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if authService.isAuthenticated {
                            Button("Sign Out") {
                                showingLogoutAlert = true
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Device Section
                Section("Device") {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.green)
                        Text("iPhone")
                        Spacer()
                        if authService.deviceToken != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(.blue)
                        Text("Apple Watch")
                        Spacer()
                        if authService.deviceToken != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    if let code = pairingCode {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Pairing Code")
                                    .font(.subheadline).bold()
                                Spacer()
                                Text(code)
                                    .font(.title2).monospacedDigit()
                            }
                            if let expires = pairingExpires {
                                Text("Expires at \(expires)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    if let pairingError = pairingError {
                        Text(pairingError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button {
                        Task { await generatePairingCode() }
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text(isGeneratingCode ? "Generating..." : "Generate Pairing Code")
                        }
                    }
                    .disabled(isGeneratingCode || !authService.isAuthenticated)
                }
                
                // Backend Section
                Section("Backend") {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.purple)
                        Text("Server Status")
                        Spacer()
                        
                        HStack {
                            Circle()
                                .fill(backendService.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(backendService.isConnected ? "Connected" : "Disconnected")
                                .font(.caption)
                        }
                    }
                    
                    Button("Test Connection") {
                        Task {
                            await backendService.testConnection()
                        }
                    }
                    
                    Button("Backend Status") {
                        showingBackendStatus = true
                    }
                }
                
                // App Section
                Section("App") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Debug Section
                Section("Debug") {
                    Button("Clear Cache") {
                        // Clear app cache
                    }
                    
                    Button("Reset App") {
                        // Reset app to initial state
                    }
                    .foregroundColor(.red)
                }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .onAppear {
                // Configure navigation bar appearance for dark theme
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingBackendStatus) {
                BackendStatusView()
            }
        }
    }

    private func generatePairingCode() async {
        guard let userToken = authService.userAccessToken else {
            pairingError = "Please sign in first."
            return
        }
        pairingError = nil
        isGeneratingCode = true
        let result = await backendService.generatePairingCode(userToken: userToken)
        await MainActor.run {
            isGeneratingCode = false
            switch result {
            case .success(let response):
                pairingCode = response.pairingCode
                pairingExpires = response.expiresAt
            case .failure(let error):
                pairingError = error.localizedDescription
            }
        }
    }
}

#Preview {
    SettingsView()
}
