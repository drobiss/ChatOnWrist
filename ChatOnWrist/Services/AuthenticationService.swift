//
//  AuthenticationService.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine
import AuthenticationServices

@MainActor
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
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signOut() {
        print("📱 Signing out...")
        userAccessToken = nil
        deviceToken = nil
        isAuthenticated = false
        errorMessage = nil
        
        keychain.delete(key: "userAccessToken")
        keychain.delete(key: "deviceToken")
        
        print("📱 Sign out complete, isAuthenticated = \(isAuthenticated)")
        
        // Notify Watch to logout as well
        NotificationCenter.default.post(name: .userLoggedOut, object: nil)
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
                
                // Notify that authentication completed (Watch can request token if needed)
                NotificationCenter.default.post(name: .userAuthenticated, object: nil)
            case .failure(let error):
                print("Authentication failed: \(error.localizedDescription)")
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Failed to get Apple ID token"
            isLoading = false
            return
        }
        
        print("✅ Apple Sign in successful, user ID: \(appleIDCredential.user)")
        Task {
            await authenticateWithBackend(appleIDToken: tokenString)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign in failed: \(error.localizedDescription)")
        isLoading = false
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                errorMessage = "Sign in was canceled"
            case .failed:
                errorMessage = "Sign in failed. Please try again."
            case .invalidResponse:
                errorMessage = "Invalid response from Apple"
            case .notHandled:
                errorMessage = "Sign in request could not be handled"
            case .unknown:
                errorMessage = "An unknown error occurred"
            @unknown default:
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found for Apple Sign in presentation")
        }
        return window
    }
}

