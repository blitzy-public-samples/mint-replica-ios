// External dependencies versions:
// Foundation: 5.5+
// Combine: 5.5+
// SwiftUI: 5.5+

import Foundation
import Combine
import SwiftUI

// MARK: - Human Tasks
// 1. Verify error handling strategy with team lead
// 2. Review account refresh frequency with product team
// 3. Add analytics tracking for account operations (to be implemented by analytics team)
// 4. Set up monitoring for account sync failures

/// ViewModel responsible for managing account-related data and business logic
/// Requirements addressed:
/// - Financial Account Integration (Technical Specification/1.2 Scope/Core Features)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
/// - SwiftUI + Combine (Technical Specification/Constraints for the AI to Generate a New iOS App/1)
@MainActor
final class AccountViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Protocol Conformance
    
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Properties
    
    private let accountService: MockAccountService
    
    // MARK: - Initialization
    
    init(accountService: MockAccountService) {
        self.accountService = accountService
        initialize()
    }
    
    // MARK: - Public Methods
    
    /// Initializes the ViewModel by setting up subscriptions and fetching initial data
    func initialize() {
        setupAccountUpdateSubscription()
        Task {
            await fetchAccounts()
        }
    }
    
    /// Fetches all accounts from the service
    @MainActor
    func fetchAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            accounts = try await accountService.fetchAccounts()
        } catch {
            errorMessage = "Failed to fetch accounts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Links a new financial account
    /// - Parameters:
    ///   - institutionId: Identifier of the financial institution
    ///   - accountType: Type of account to link
    /// - Returns: The newly linked account
    @MainActor
    func linkNewAccount(institutionId: String, accountType: AccountType) async -> Account? {
        isLoading = true
        errorMessage = nil
        
        do {
            let newAccount = try await accountService.linkAccount(
                institutionId: institutionId,
                type: accountType
            )
            return newAccount
        } catch {
            errorMessage = "Failed to link account: \(error.localizedDescription)"
            return nil
        } finally {
            isLoading = false
        }
    }
    
    /// Refreshes data for a specific account
    /// - Parameter accountId: Identifier of the account to refresh
    @MainActor
    func refreshAccount(accountId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await accountService.refreshAccount(id: accountId)
        } catch {
            errorMessage = "Failed to refresh account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Performs cleanup when ViewModel is being deallocated
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        accounts.removeAll()
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// Sets up subscription to account updates from the service
    private func setupAccountUpdateSubscription() {
        accountService.accountUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedAccount in
                guard let self = self else { return }
                
                if let index = self.accounts.firstIndex(where: { $0.id == updatedAccount.id }) {
                    self.accounts[index] = updatedAccount
                } else {
                    self.accounts.append(updatedAccount)
                }
            }
            .store(in: &cancellables)
    }
}