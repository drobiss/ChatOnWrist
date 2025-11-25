//
//  AuthenticationService.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userAccessToken: String?
    @Published var deviceToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychain = KeychainService()
    private let backendService = BackendService()
    private var watchConnectivity: WatchConnectivityService?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadStoredTokens()
        setupTokenListener()
    }
    
    func configure(watchConnectivity: WatchConnectivityService) {
        self.watchConnectivity = watchConnectivity
        
        // Check both property and keychain (in case token was just received but property not updated yet)
        let hasTokenInProperty = userAccessToken != nil
        let tokenFromKeychain = keychain.load(key: "userAccessToken")
        
        if !hasTokenInProperty && tokenFromKeychain == nil {
            print("⌚️ AuthenticationService: No token found, requesting from iPhone")
            requestTokenFromiPhone()
        } else {
            // If token exists in keychain but not in property, load it
            if !hasTokenInProperty, let token = tokenFromKeychain {
                print("⌚️ AuthenticationService: Token found in keychain, loading it")
                userAccessToken = token
            }
            
            // If we have a token, verify it's still valid by requesting from iPhone
            // This ensures we're not logged in if iPhone logged out
            if userAccessToken != nil {
                print("⌚️ AuthenticationService: Token found, verifying with iPhone...")
                // Request token from iPhone - if iPhone is logged out, it won't send one
                // and we'll clear our token after a timeout
                requestTokenFromiPhone()
                
                // If iPhone doesn't respond with a token within 3 seconds, assume logged out
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    guard let self = self else { return }
                    // If we still don't have a confirmed token, clear it
                    // (This will be set to true if iPhone sends a token)
                    if !self.isAuthenticated && self.userAccessToken != nil {
                        print("⌚️ iPhone didn't confirm token - assuming logged out")
                        self.signOut()
                    }
                }
            } else {
                print("⌚️ AuthenticationService: Token already available")
                // Token is already set and authenticated (from notification)
            }
        }
    }
    
    private func setupTokenListener() {
        // Listen for token from iPhone
        NotificationCenter.default.publisher(for: .iphoneUserTokenReceived)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let token = userInfo["token"] as? String else {
                    print("⌚️ Received token notification but token is missing")
                    return
                }
                
                print("⌚️ AuthenticationService: Processing received token")
                Task { @MainActor in
                    self.userAccessToken = token
                    let saved = self.keychain.save(key: "userAccessToken", value: token)
                    print("⌚️ Token saved to keychain: \(saved)")
                    self.isAuthenticated = true
                    print("⌚️ Authentication state updated: isAuthenticated = \(self.isAuthenticated)")
                }
            }
            .store(in: &cancellables)
        
        // Listen for logout from iPhone
        NotificationCenter.default.publisher(for: .iphoneLogoutReceived)
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("⌚️ AuthenticationService: Received logout signal from iPhone - signing out")
                Task { @MainActor in
                    self.signOut()
                    print("⌚️ AuthenticationService: Sign out complete, isAuthenticated = \(self.isAuthenticated)")
                }
            }
            .store(in: &cancellables)
    }
    
    private func requestTokenFromiPhone() {
        guard let watchConnectivity = watchConnectivity else {
            // WatchConnectivity not configured yet, will request later
            return
        }
        
        print("⌚️ No token found, requesting from iPhone...")
        watchConnectivity.requestUserTokenFromiPhone()
        
        // Retry after a delay if iPhone is not immediately reachable
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.userAccessToken == nil else { return }
            print("⌚️ Still no token, retrying request...")
            watchConnectivity.requestUserTokenFromiPhone()
        }
    }
    
    func signOut() {
        print("⌚️ AuthenticationService: Signing out...")
        userAccessToken = nil
        deviceToken = nil
        isAuthenticated = false
        errorMessage = nil
        
        let tokenDeleted = keychain.delete(key: "userAccessToken")
        let deviceTokenDeleted = keychain.delete(key: "deviceToken")
        print("⌚️ Token deleted: \(tokenDeleted), Device token deleted: \(deviceTokenDeleted)")
        print("⌚️ Sign out complete")
    }
    
    func pairDevice(pairingCode: String) async -> Bool {
        guard let userToken = userAccessToken else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let result = await backendService.pairDevice(pairingCode: pairingCode, userToken: userToken)
        
        await MainActor.run {
            self.isLoading = false
            
            switch result {
            case .success(let response):
                self.deviceToken = response.deviceToken
                self.keychain.save(key: "deviceToken", value: response.deviceToken)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
        
        return deviceToken != nil
    }
    
    private func loadStoredTokens() {
        if let storedUserToken = keychain.load(key: "userAccessToken") {
            print("⌚️ Loaded stored user token from keychain")
            // Don't set isAuthenticated yet - wait to verify with iPhone
            // This prevents staying logged in if iPhone logged out while Watch was off
            userAccessToken = storedUserToken
            // We'll verify this token is still valid when WatchConnectivity is configured
        } else {
            print("⌚️ No stored user token found in keychain")
        }
        
        if let storedDeviceToken = keychain.load(key: "deviceToken") {
            deviceToken = storedDeviceToken
        }
    }
    
    func authenticateWithBackend(appleIDToken: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("Starting authentication with backend...")
        let result = await backendService.authenticateUser(appleIDToken: appleIDToken)
        
        await MainActor.run {
            self.isLoading = false
            
            switch result {
            case .success(let response):
                print("Authentication successful!")
                self.userAccessToken = response.userToken
                self.isAuthenticated = true
                self.keychain.save(key: "userAccessToken", value: response.userToken)
            case .failure(let error):
                print("Authentication failed: \(error.localizedDescription)")
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        }
    }
}
