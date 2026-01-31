//
//  AuthService.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import Foundation
import FirebaseAuth
import Combine
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isLoading = true
    
    private var cancellables = Set<AnyCancellable>()
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.currentUser = user
            self.isLoading = false
        }
    }
    
    // MARK: - Auth Actions
    
    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // 1. Sign in with Google
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        // 2. Get tokens
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token"])
        }
        let accessToken = result.user.accessToken.tokenString
        
        // 3. Create Firebase Credential
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        // 4. Sign in to Firebase
        try await Auth.auth().signIn(with: credential)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
}
