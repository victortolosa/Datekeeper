//
//  LoginView.swift
//  Datekeeper
//
//  Created by Victor Tolosa on 1/30/26.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Datekeeper")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            Text("Welcome Back")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            GoogleSignInButton(action: signInWithGoogle)
                .frame(height: 50)
                .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func signInWithGoogle() {
        errorMessage = nil
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    LoginView()
}
