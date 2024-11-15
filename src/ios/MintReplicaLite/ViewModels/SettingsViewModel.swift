// External dependencies versions:
// Combine: 5.5+
// Foundation: 5.5+

import Combine
import Foundation

// Relative imports
import "../Core/Protocols/ViewModelProtocol"
import "../Models/User"
import "../Mocks/MockAuthService"

/// Human Tasks:
/// 1. Ensure UserDefaults keys are properly configured in Constants.swift
/// 2. Verify biometric authentication entitlements are set up
/// 3. Add appropriate usage description strings in Info.plist for notifications

/// ViewModel responsible for managing user settings and preferences
/// Requirements addressed:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
@MainActor
final class SettingsViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var currentUser: User?
    @Published var isBiometricEnabled: Bool = false
    @Published var isNotificationsEnabled: Bool = true
    @Published var selectedCurrency: String = "USD"
    
    // MARK: - Private Properties
    private let authService: MockAuthService
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(authService: MockAuthService) {
        self.authService = authService
        initialize()
    }
    
    // MARK: - ViewModelProtocol Implementation
    func initialize() {
        // Load current user settings from UserDefaults
        loadUserSettings()
        
        // Set up bindings
        setupBindings()
    }
    
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func updateProfile(firstName: String, lastName: String, email: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self, let user = self.currentUser else {
                promise(.failure(NSError(domain: "SettingsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user found"])))
                return
            }
            
            // Update user properties
            let updatedUser = User(
                id: user.id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                preferredCurrency: user.preferredCurrency
            )
            updatedUser.hasBiometricEnabled = user.hasBiometricEnabled
            updatedUser.notificationsEnabled = user.notificationsEnabled
            
            self.currentUser = updatedUser
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    func toggleBiometricAuth() -> AnyPublisher<Bool, Error> {
        isLoading = true
        
        return authService.authenticateWithBiometrics()
            .map { [weak self] success in
                if success {
                    self?.isBiometricEnabled.toggle()
                    self?.currentUser?.hasBiometricEnabled = self?.isBiometricEnabled ?? false
                    UserDefaults.standard.set(self?.isBiometricEnabled, forKey: "userBiometricEnabled")
                }
                return success
            }
            .handleEvents(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    func toggleNotifications() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SettingsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return
            }
            
            self.isNotificationsEnabled.toggle()
            self.currentUser?.notificationsEnabled = self.isNotificationsEnabled
            UserDefaults.standard.set(self.isNotificationsEnabled, forKey: "userNotificationsEnabled")
            
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    func updateCurrency(_ currency: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SettingsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])))
                return
            }
            
            // Validate currency code (basic validation)
            guard currency.count == 3 else {
                promise(.failure(NSError(domain: "SettingsViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid currency code"])))
                return
            }
            
            self.selectedCurrency = currency
            self.currentUser?.preferredCurrency = currency
            UserDefaults.standard.set(currency, forKey: "userPreferredCurrency")
            
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Error> {
        isLoading = true
        
        return authService.logout()
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure = completion {
                        self?.errorMessage = "Failed to logout"
                    } else {
                        self?.resetSettings()
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    private func loadUserSettings() {
        // Load saved settings from UserDefaults
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "userBiometricEnabled")
        isNotificationsEnabled = UserDefaults.standard.bool(forKey: "userNotificationsEnabled")
        selectedCurrency = UserDefaults.standard.string(forKey: "userPreferredCurrency") ?? "USD"
    }
    
    private func setupBindings() {
        // Observe changes to biometric settings
        $isBiometricEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.currentUser?.hasBiometricEnabled = enabled
            }
            .store(in: &cancellables)
        
        // Observe changes to notification settings
        $isNotificationsEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.currentUser?.notificationsEnabled = enabled
            }
            .store(in: &cancellables)
        
        // Observe changes to currency settings
        $selectedCurrency
            .dropFirst()
            .sink { [weak self] currency in
                self?.currentUser?.preferredCurrency = currency
            }
            .store(in: &cancellables)
    }
    
    private func resetSettings() {
        currentUser = nil
        isBiometricEnabled = false
        isNotificationsEnabled = true
        selectedCurrency = "USD"
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "userBiometricEnabled")
        UserDefaults.standard.removeObject(forKey: "userNotificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "userPreferredCurrency")
    }
}