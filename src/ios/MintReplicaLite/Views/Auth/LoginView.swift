// External dependencies versions:
// SwiftUI: 5.5+
// Combine: 5.5+

import SwiftUI
import Combine

/// Human Tasks:
/// 1. Test form validation with various input combinations
/// 2. Verify keyboard handling and input field focus behavior
/// 3. Test error message display scenarios
/// 4. Ensure proper navigation flow to registration screen
/// 5. Verify accessibility features work correctly

/// LoginView provides the main authentication interface for MintReplicaLite
/// Requirements addressed:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
struct LoginView: View {
    // MARK: - Properties
    @StateObject private var viewModel = AuthViewModel()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showBiometricAuth: Bool = false
    @State private var isSecureTextEntry: Bool = true
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background Color
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo and Welcome Text
                        VStack(spacing: 12) {
                            Image(systemName: "dollarsign.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.blue)
                            
                            Text("Welcome to MintReplicaLite")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Sign in to manage your finances")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // Login Form
                        VStack(spacing: 16) {
                            // Email Field
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            // Password Field
                            HStack {
                                if isSecureTextEntry {
                                    SecureField("Password", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.password)
                                } else {
                                    TextField("Password", text: $password)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .textContentType(.password)
                                }
                                
                                Button(action: { isSecureTextEntry.toggle() }) {
                                    Image(systemName: isSecureTextEntry ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                        
                        // Login Button
                        Button(action: loginUser) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .disabled(viewModel.isLoading)
                        
                        // Biometric Authentication Button
                        if viewModel.isBiometricEnabled {
                            Button(action: { showBiometricAuth = true }) {
                                HStack {
                                    Image(systemName: "faceid")
                                    Text("Sign in with Biometrics")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            NavigationLink("Sign Up") {
                                // Navigation to SignUpView handled by parent navigation controller
                                EmptyView()
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showBiometricAuth) {
            BiometricAuthView(viewModel: viewModel)
        }
    }
    
    // MARK: - Private Methods
    private func loginUser() {
        guard validateInputs() else { return }
        
        viewModel.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &viewModel.cancellables)
    }
    
    private func validateInputs() -> Bool {
        // Email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            viewModel.errorMessage = "Please enter a valid email address"
            return false
        }
        
        // Password validation
        guard password.count >= 8 else {
            viewModel.errorMessage = "Password must be at least 8 characters long"
            return false
        }
        
        return true
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif