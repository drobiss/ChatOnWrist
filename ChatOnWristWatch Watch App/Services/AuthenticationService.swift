//
//  AuthenticationService.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine

class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userAccessToken: String?
    @Published var deviceToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychain = KeychainService()
    private let backendService = BackendService()
    
    init() {
        loadStoredTokens()
    }
    
    func signOut() {
        userAccessToken = nil
        deviceToken = nil
        isAuthenticated = false
        errorMessage = nil
        
        keychain.delete(key: "userAccessToken")
        keychain.delete(key: "deviceToken")
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
            userAccessToken = storedUserToken
            isAuthenticated = true
        }
        
        if let storedDeviceToken = keychain.load(key: "deviceToken") {
            deviceToken = storedDeviceToken
        }
    }
}
