//
//  WatchHomeView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct WatchHomeView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    
    @Binding var shouldStartDictation: Bool
    
    @State private var showHistorySheet = false
    @State private var showVoiceSettingsSheet = false
    @State private var showMenuSheet = false
    @State private var navigateToChat = false
    @State private var conversationToNavigate: Conversation?
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: CGFloat = 0.5
    
    var body: some View {
        NavigationStack {
            ZStack {
                // True black with subtle glow
                background
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Hero mic button - perfectly centered
                    heroMicButton
                    
                    Spacer()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear
                    .frame(height: 0)
            }
            .overlay(alignment: .topLeading) {
                topMenu
                    .offset(y: -24)
            }
            .navigationDestination(isPresented: $navigateToChat) {
                Group {
                    if let conversation = conversationToNavigate {
                        WatchChatView(conversation: conversation)
                            .environmentObject(conversationStore)
                            .environmentObject(authService)
                            .environmentObject(watchConnectivity)
                            .onAppear {
                                // Reset after navigation
                                conversationToNavigate = nil
                            }
                    } else {
                        WatchChatView()
                            .environmentObject(conversationStore)
                            .environmentObject(authService)
                            .environmentObject(watchConnectivity)
                    }
                }
            }
            .sheet(isPresented: $showHistorySheet) {
                WatchHistoryView(onConversationSelected: { conversation in
                    // Dismiss the sheet and navigate from main navigation stack
                    showHistorySheet = false
                    conversationToNavigate = conversation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToChat = true
                    }
                })
                    .environmentObject(conversationStore)
            }
            .sheet(isPresented: $showVoiceSettingsSheet) {
                VoiceSettingsView()
            }
            .sheet(isPresented: $showMenuSheet) {
                menuOptionsSheet
            }
            .onChange(of: shouldStartDictation) { oldValue, newValue in
                if newValue {
                    // Reset flag and navigate to chat (real-time voice)
                    shouldStartDictation = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startRealtimeVoiceChat()
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var background: some View {
        ZStack {
            WatchPalette.background.ignoresSafeArea()
            WatchPalette.backgroundGlow
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Hero Mic Button
    
    private var heroMicButton: some View {
        VStack(spacing: 18) {
            Button(action: startRealtimeVoiceChat) {
                ZStack {
                    // Outer pulse ring - smooth Apple-style pulse
                    Circle()
                        .stroke(
                            WatchPalette.accent.opacity(0.5),
                            lineWidth: 1
                        )
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                    
                    // Main button - liquid glass with subtle blue border
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 92, height: 92)
                        .overlay(
                            Circle()
                                .stroke(
                                    WatchPalette.accent.opacity(0.8),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(HeroButtonStyle())
            .accessibilityLabel("Start real-time voice chat")
            
            Text("Tap to speak")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(WatchPalette.textSecondary)
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        func animatePulse() {
            pulseScale = 1.0
            pulseOpacity = 0.5
            
            withAnimation(.easeOut(duration: 1.8)) {
                pulseScale = 1.25
                pulseOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                animatePulse()
            }
        }
        
        animatePulse()
    }
    
    
    // MARK: - Top Menu
    
    private var topMenu: some View {
        Button(action: { showMenuSheet = true }) {
            ZStack {
                // Enhanced glass effect - floating above background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                
                // White ellipsis - matching Apple X icon style
                Image(systemName: "ellipsis")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(GlassMenuButtonStyle())
        .padding(.leading, 16)
    }
    
    private var menuOptionsSheet: some View {
        VStack(spacing: 16) {
            Button(action: {
                showMenuSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showHistorySheet = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("History")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(WatchPalette.accent)
                )
            }
            .buttonStyle(.plain)
            
            Button(action: {
                showMenuSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showVoiceSettingsSheet = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "gear")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Settings")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(WatchPalette.accent)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .background(WatchPalette.background.ignoresSafeArea())
    }
    
    // MARK: - Actions
    
    private func startRealtimeVoiceChat() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        
        // Always create a new conversation when starting from main screen
        _ = conversationStore.createNewConversation()
        
        // Navigate directly to chat view - user will use real-time voice there
        navigateToChat = true
    }
}

// MARK: - Button Styles

private struct HeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct GlassMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    WatchHomeView(shouldStartDictation: Binding.constant(false))
        .environmentObject(ConversationStore())
        .environmentObject(AuthenticationService())
        .environmentObject(WatchConnectivityService())
}
