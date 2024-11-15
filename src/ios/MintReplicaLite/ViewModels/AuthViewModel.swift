// External dependencies versions:
// Foundation: 5.5+
// Combine: 5.5+
// SwiftUI: 5.5+

import Foundation
import Combine
import SwiftUI

// Relative imports
import "../Core/Protocols/ViewModelProtocol"
import "../Mocks/MockAuthService"
import "../Models/User"

/// Human Tasks:
/// 1. Verify Keychain access is properly configured for secure credential storage
/// 2. Ensure proper error handling and user feedback mechanisms are in place
/// 3. Test biometric authentication flow on physical devices

/// AuthViewModel manages authentication state and operations in the MintReplicaLite application
/// Requirements addressed:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
@MainActor
final class AuthViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    @Published private(set) var isLoading: Bool
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var isBiometricEnabled: Bool
    
    // MARK: - Private Properties
    var cancellables: Set<AnyCancellable>
    private let authService: MockAuthService
    
    // MARK: - Initialization
    init() {
        self.cancellables = Set<AnyCancellable>()
        self.authService = MockAuthService()
        self.isLoading = false
        self.errorMessage = nil
        self.currentUser = nil
        self.isAuthenticated = false
        self.isBiometricEnabled = false
        
        initialize()
    }
    
    // MARK: - ViewModelProtocol Implementation
    func initialize() {
        // Set up Combine subscribers for auth state changes
        $currentUser
            .map { $0 != nil }
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        $currentUser
            .map { $0?.hasBiometricEnabled ?? false }
            .assign(to: \.isBiometricEnabled, on: self)
            .store(in: &cancellables)
    }
    
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        currentUser = nil
        isAuthenticated = false
        isBiometricEnabled = false
        errorMessage = nil
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) -> AnyPublisher<Bool, Never> {
        isLoading = true
        errorMessage = nil
        
        return authService.login(email: email, password: password)
            .map { [weak self] user -> Bool in
                self?.currentUser = user
                return true
            }
            .catch { [weak self] error -> AnyPublisher<Bool, Never> in
                self?.errorMessage = error.localizedDescription
                return Just(false).eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) -> AnyPublisher<Bool, Never> {
        isLoading = true
        errorMessage = nil
        
        return authService.register(email: email, password: password, firstName: firstName, lastName: lastName)
            .map { [weak self] user -> Bool in
                self?.currentUser = user
                return true
            }
            .catch { [weak self] error -> AnyPublisher<Bool, Never> in
                self?.errorMessage = error.localizedDescription
                return Just(false).eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Bool, Never> {
        isLoading = true
        
        return authService.logout()
            .map { [weak self] _ -> Bool in
                self?.currentUser = nil
                return true
            }
            .catch { [weak self] error -> AnyPublisher<Bool, Never> in
                self?.errorMessage = error.localizedDescription
                return Just(false).eraseToAnyPublisher()
            }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func authenticateWithBiometrics() -> AnyPublisher<Bool, Never> {
        guard isBiometricEnabled else {
            errorMessage = "Biometric authentication is not enabled"
            return Just(false).eraseToAnyPublisher()
        }
        
        isLoading = true
        
        return authService.authenticateWithBiometrics()
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .catch { [weak self] error -> AnyPublisher<Bool, Never> in
                self?.errorMessage = error.localizedDescription
                return Just(false).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}