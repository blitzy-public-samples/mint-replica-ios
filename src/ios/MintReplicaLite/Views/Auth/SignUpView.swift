// External dependencies versions:
// SwiftUI: 5.5+
// Combine: 5.5+

import SwiftUI
import Combine

// Relative imports
import "../../ViewModels/AuthViewModel"
import "../../Core/Extensions/View+Extensions"

/// Human Tasks:
/// 1. Verify password requirements match security policy
/// 2. Implement password strength indicator
/// 3. Configure terms and conditions content
/// 4. Set up proper keyboard handling and input validation

/// SignUpView provides user registration functionality with form validation
/// Requirements addressed:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
struct SignUpView: View {
    // MARK: - Properties
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    
    // UI state
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var showTermsSheet = false
    @State private var acceptedTerms = false
    
    // MARK: - Constants
    private let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
    private let passwordMinLength = 8
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Form fields
                Group {
                    // Name fields
                    HStack {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                        
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }
                    
                    // Email field
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    // Password field
                    ZStack(alignment: .trailing) {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                        }
                        
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .accessibleTapTarget()
                    }
                    
                    // Confirm password field
                    ZStack(alignment: .trailing) {
                        if isConfirmPasswordVisible {
                            TextField("Confirm Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                        }
                        
                        Button(action: { isConfirmPasswordVisible.toggle() }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .accessibleTapTarget()
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .standardPadding()
                
                // Terms acceptance
                HStack {
                    Button(action: { acceptedTerms.toggle() }) {
                        Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(acceptedTerms ? .blue : .gray)
                    }
                    .accessibleTapTarget()
                    
                    Text("I accept the ")
                    Button("Terms and Conditions") {
                        showTermsSheet = true
                    }
                }
                .standardPadding()
                
                // Sign up button
                Button(action: signUp) {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(validateForm() ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!validateForm())
                .accessibleTapTarget()
                .standardPadding()
                
                // Login link
                HStack {
                    Text("Already have an account?")
                    Button("Log In") {
                        dismiss()
                    }
                }
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showTermsSheet) {
            Text("Terms and Conditions")
                .standardPadding()
        }
        .alert("Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
        .loadingOverlay(authViewModel.isLoading)
    }
    
    // MARK: - Form Validation
    private func validateForm() -> Bool {
        guard !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty,
              acceptedTerms else {
            return false
        }
        
        guard emailPredicate.evaluate(with: email) else {
            return false
        }
        
        guard password.count >= passwordMinLength,
              password.rangeOfCharacter(from: .uppercaseLetters) != nil,
              password.rangeOfCharacter(from: .lowercaseLetters) != nil,
              password.rangeOfCharacter(from: .decimalDigits) != nil,
              password.rangeOfCharacter(from: .punctuationCharacters) != nil else {
            return false
        }
        
        return password == confirmPassword
    }
    
    // MARK: - Actions
    private func signUp() {
        guard validateForm() else { return }
        
        let cancellable = authViewModel.register(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        .sink { success in
            if success {
                dismiss()
            }
        }
        
        // Store cancellable to prevent premature deallocation
        _ = cancellable
    }
}

#if DEBUG
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
#endif