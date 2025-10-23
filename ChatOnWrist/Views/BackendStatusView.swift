//
//  BackendStatusView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct BackendStatusView: View {
    @StateObject private var backendService = BackendService()
    @StateObject private var testService = BackendTestService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Connection Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Backend Status")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(backendService.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(backendService.isConnected ? "Connected" : "Disconnected")
                            .fontWeight(.medium)
                    }
                    
                    if let errorMessage = backendService.errorMessage {
                        Text("Error: \(errorMessage)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if let lastTest = backendService.lastConnectionTest {
                        Text("Last test: \(lastTest, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Test Results
                VStack(alignment: .leading, spacing: 12) {
                    Text("Test Results")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text(testService.connectionStatus.description)
                            .fontWeight(.medium)
                    }
                    
                    if let lastTest = testService.lastTestTime {
                        HStack {
                            Text("Last test:")
                            Spacer()
                            Text(lastTest, style: .relative)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Test Connection") {
                        Task {
                            await testService.testConnection()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Refresh Backend Status") {
                        Task {
                            await backendService.testConnection()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Backend URL Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configuration")
                        .font(.headline)
                    
                    Text("Backend URL: \(AppConfig.backendBaseURL)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("OpenAI Model: \(AppConfig.model)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Backend Status")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    BackendStatusView()
}
