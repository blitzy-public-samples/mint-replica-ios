// Foundation v5.5+
import Foundation
// Combine v5.5+
import Combine
// LocalAuthentication v5.5+
import LocalAuthentication

// Relative imports
import "../Models/User"
import "../Core/Utilities/Constants"

/// Human Tasks:
/// 1. Ensure LocalAuthentication framework is properly configured in project settings
/// 2. Verify biometric authentication is enabled in app entitlements
/// 3. Add appropriate usage description strings in Info.plist for biometric authentication

/// Mock implementation of authentication service for testing and development
/// Addresses requirements:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
protocol AuthServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<User, Error>
    func register(email: String, password: String, firstName: String, lastName: String) -> AnyPublisher<User, Error>
    func logout() -> AnyPublisher<Void, Error>
    func authenticateWithBiometrics() -> AnyPublisher<Bool, Error>
}

class MockAuthService: AuthServiceProtocol {
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let biometricContext: LAContext
    private var currentUser: User?
    private var isBiometricEnabled: Bool
    
    // MARK: - Error Types
    enum MockAuthError: Error {
        case invalidCredentials
        case invalidEmail
        case weakPassword
        case biometricNotAvailable
        case userNotAuthenticated
        case biometricNotEnabled
    }
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.biometricContext = LAContext()
        self.isBiometricEnabled = false
        self.currentUser = nil
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { [weak self] promise in
            guard self?.isValidEmail(email) == true else {
                promise(.failure(MockAuthError.invalidEmail))
                return
            }
            
            // Simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Create mock user
                let mockUser = User(
                    id: UUID().uuidString,
                    email: email,
                    firstName: "Mock",
                    lastName: "User",
                    preferredCurrency: "USD"
                )
                
                // Set biometric status
                mockUser.hasBiometricEnabled = self?.isBiometricEnabled ?? false
                
                // Update login date
                mockUser.updateLastLoginDate()
                
                // Store mock token
                self?.userDefaults.set("mock_auth_token_\(mockUser.id)", forKey: UserDefaultsKeys.userToken)
                
                // Update current user
                self?.currentUser = mockUser
                
                promise(.success(mockUser))
            }
        }.eraseToAnyPublisher()
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { [weak self] promise in
            guard self?.isValidEmail(email) == true else {
                promise(.failure(MockAuthError.invalidEmail))
                return
            }
            
            guard self?.isValidPassword(password) == true else {
                promise(.failure(MockAuthError.weakPassword))
                return
            }
            
            // Simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Create new mock user
                let newUser = User(
                    id: UUID().uuidString,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    preferredCurrency: "USD"
                )
                
                // Set biometric status to false for new users
                newUser.hasBiometricEnabled = false
                
                // Store mock token
                self?.userDefaults.set("mock_auth_token_\(newUser.id)", forKey: UserDefaultsKeys.userToken)
                
                // Update current user
                self?.currentUser = newUser
                
                promise(.success(newUser))
            }
        }.eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            // Remove auth token
            self?.userDefaults.removeObject(forKey: UserDefaultsKeys.userToken)
            
            // Clear current user
            self?.currentUser = nil
            
            // Simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    func authenticateWithBiometrics() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockAuthError.biometricNotAvailable))
                return
            }
            
            guard self.currentUser != nil else {
                promise(.failure(MockAuthError.userNotAuthenticated))
                return
            }
            
            guard self.currentUser?.hasBiometricEnabled == true else {
                promise(.failure(MockAuthError.biometricNotEnabled))
                return
            }
            
            var error: NSError?
            guard self.biometricContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                promise(.failure(error ?? MockAuthError.biometricNotAvailable))
                return
            }
            
            // Simulate successful biometric authentication
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(true))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Password must be at least 8 characters
        return password.count >= 8
    }
}