//
//  WatchHomeView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    @State private var showHistory = false
    @State private var isAnySheetPresented = false
    @StateObject private var dictationService = DictationService()
    @State private var navigateToChat = false
    @State private var isPulsing = false
    @State private var pulse = false
    @State private var showSettingsPanel = false
    @State private var showVoiceSettingsSheet = false
    @State private var pendingDictationText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Glassmorphism background
                Color.black
                    .ignoresSafeArea()
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                // Ensure background never participates in implicit animations
                .animation(nil, value: isPulsing)
                
                VStack(spacing: 14) {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showSettingsPanel.toggle()
                            }
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    // Central pulsing microphone button (stable center pulse)
                    ZStack {
                        // Soft glow ring with opacity breathing (no scaling to avoid drift)
                        Circle()
                            .strokeBorder(Color.white.opacity(pulse ? 0.42 : 0.2), lineWidth: pulse ? 3 : 2)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.32),
                                                Color.white.opacity(0.08)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 5
                                    )
                                    .scaleEffect(pulse ? 1.06 : 0.97)
                                    .opacity(pulse ? 0.36 : 0.16)
                                    .blur(radius: 2)
                            )
                            .overlay(
                                Circle()
                                    .fill(Color.white.opacity(pulse ? 0.18 : 0.06))
                                    .frame(width: 122, height: 122)
                                    .blur(radius: 9)
                            )
                        
                        Button(action: startVoiceAndOpenChat) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ), lineWidth: 1
                                            )
                                    )
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    
                    Text("Tap to speak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 4)
                    
                    // Hidden navigation to chat when ready
                    NavigationLink(destination: WatchChatView(initialMessage: pendingDictationText)
                        .environmentObject(conversationStore)
                        .environmentObject(authService), isActive: $navigateToChat) { EmptyView() }
                        .hidden()
                        .onChange(of: navigateToChat) { newValue in
                            if !newValue {
                                pendingDictationText = nil
                            }
                        }
                    
                    Spacer()
                }
                .padding(12)
                .onAppear {
                    isPulsing = true
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulse.toggle()
                    }
                }
            }
            .overlay(alignment: .top) {
                if showSettingsPanel {
                    QuickAccessPanel(
                        onCollapse: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                showSettingsPanel = false
                            }
                        },
                        onSettingsTap: {
                            guard !isAnySheetPresented else { return }
                            isAnySheetPresented = true
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                showSettingsPanel = false
                            }
                            showVoiceSettingsSheet = true
                        },
                        onHistoryTap: {
                            guard !isAnySheetPresented else { return }
                            showHistory = true
                            isAnySheetPresented = true
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                showSettingsPanel = false
                            }
                        }
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 22)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showHistory, onDismiss: { isAnySheetPresented = false }) {
                WatchHistoryView()
                    .environmentObject(conversationStore)
            }
            .sheet(isPresented: $showVoiceSettingsSheet, onDismiss: { isAnySheetPresented = false }) {
                VoiceSettingsView()
            }
        }
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Quick Access Panel
private struct QuickAccessPanel: View {
    var onCollapse: () -> Void
    var onSettingsTap: () -> Void
    var onHistoryTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: onCollapse) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 32, height: 4)
                    .padding(.top, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 18) {
                QuickActionButton(
                    iconName: "gearshape.fill",
                    action: onSettingsTap
                )
                
                QuickActionButton(
                    iconName: "clock.fill",
                    action: onHistoryTap
                )
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                )
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
        )
    }
}

private struct QuickActionButton: View {
    var iconName: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
                    .frame(width: 62, height: 62)
                
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .frame(width: 62, height: 62)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Actions
private extension WatchHomeView {
    func startVoiceAndOpenChat() {
        dictationService.requestDictation(initialText: nil) { text in
            guard
                let content = text?.trimmingCharacters(in: .whitespacesAndNewlines),
                !content.isEmpty
            else {
                // Stay on the home screen when dictation is cancelled or empty
                navigateToChat = false
                return
            }
            if conversationStore.currentConversation == nil {
                _ = conversationStore.createNewConversation()
            }
            pendingDictationText = content
            navigateToChat = true
        }
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(ConversationStore())
        .environmentObject(AuthenticationService())
        .environmentObject(WatchConnectivityService())
}
