//
//  AuthenticationService.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine
import AuthenticationServices

class AuthenticationService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userAccessToken: String?
    @Published var deviceToken: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let keychain = KeychainService()
    private let backendService = BackendService()
    
    override init() {
        super.init()
        loadStoredTokens()
    }
    
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
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

extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            return
        }
        
        Task {
            await authenticateWithBackend(appleIDToken: tokenString)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func authenticateWithBackend(appleIDToken: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // For testing, simulate successful authentication
        await MainActor.run {
            self.userAccessToken = "mock_user_token_\(UUID().uuidString)"
            self.isAuthenticated = true
            self.keychain.save(key: "userAccessToken", value: self.userAccessToken ?? "")
            self.isLoading = false
        }
        
        // TODO: Uncomment when backend is running
        /*
        let result = await backendService.authenticateUser(appleIDToken: appleIDToken)
        
        await MainActor.run {
            self.isLoading = false
            
            switch result {
            case .success(let response):
                self.userAccessToken = response.userToken
                self.isAuthenticated = true
                self.keychain.save(key: "userAccessToken", value: response.userToken)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
        */
    }
}

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
}
