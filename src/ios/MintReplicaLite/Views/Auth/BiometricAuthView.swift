// External dependencies versions:
// SwiftUI: 5.5+
// LocalAuthentication: 5.5+
// Combine: 5.5+

import SwiftUI
import LocalAuthentication
import Combine

/// Human Tasks:
/// 1. Test biometric authentication on physical devices with both Face ID and Touch ID
/// 2. Verify proper error handling and user feedback in production environment
/// 3. Ensure accessibility features work correctly with biometric authentication UI

/// BiometricAuthView provides a user interface for biometric authentication
/// Requirements addressed:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
struct BiometricAuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Private Properties
    private let biometricType: LABiometryType = {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }()
    
    // MARK: - Initialization
    init(viewModel: AuthViewModel = AuthViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Biometric Icon
            Group {
                switch biometricType {
                case .faceID:
                    Image(systemName: "faceid")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                case .touchID:
                    Image(systemName: "touchid")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                default:
                    Image(systemName: "exclamationmark.shield")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                }
            }
            .foregroundColor(.blue)
            .padding(.bottom, 16)
            
            // Authentication Text
            Text(biometricType == .faceID ? "Authenticate with Face ID" : "Authenticate with Touch ID")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Loading Indicator
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
            
            // Retry Button
            if !viewModel.isLoading {
                Button(action: authenticate) {
                    Text(viewModel.errorMessage != nil ? "Retry" : "Authenticate")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                .disabled(!viewModel.isBiometricEnabled)
            }
            
            // Cancel Button
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .onAppear {
            if viewModel.isBiometricEnabled {
                authenticate()
            }
        }
    }
    
    // MARK: - Authentication Method
    private func authenticate() {
        viewModel.authenticateWithBiometrics()
            .receive(on: DispatchQueue.main)
            .sink { success in
                if success {
                    dismiss()
                }
            }
            .store(in: &viewModel.cancellables)
    }
}