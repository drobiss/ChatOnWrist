//
//  BackendStatusView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct BackendStatusView: View {
    @StateObject private var backendService = BackendService()
    @Environment(\.dismiss) private var dismiss
    
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
                    // Connection Status Section
                    Section("Connection Status") {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.purple)
                            Text("Status")
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(backendService.isConnected ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                Text(backendService.isConnected ? "Connected" : "Disconnected")
                                    .font(.subheadline)
                                    .foregroundColor(backendService.isConnected ? .green : .red)
                            }
                        }
                        
                        if let errorMessage = backendService.errorMessage {
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Error")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(errorMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    // Backend Information Section
                    Section("Backend Information") {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("Base URL")
                            Spacer()
                            Text(AppConfig.backendBaseURL)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        if let lastTest = backendService.lastConnectionTest {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                Text("Last Test")
                                Spacer()
                                Text(lastTest, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                Text("Last Test")
                                Spacer()
                                Text("Never")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Actions Section
                    Section("Actions") {
                        Button(action: {
                            Task {
                                await backendService.testConnection()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                Text("Test Connection")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Backend Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                // Configure navigation bar appearance for dark theme
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
            }
        }
    }
}

#Preview {
    BackendStatusView()
}



