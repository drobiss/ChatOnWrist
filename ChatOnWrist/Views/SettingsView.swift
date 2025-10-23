//
//  SettingsView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var backendService = BackendService()
    @StateObject private var backendTestService = BackendTestService()
    
    @State private var showingBackendStatus = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
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
                            await backendTestService.testConnection()
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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
}

#Preview {
    SettingsView()
}
