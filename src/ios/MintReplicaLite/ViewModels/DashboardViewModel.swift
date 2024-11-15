// External dependencies versions:
// Foundation: 5.5+
// Combine: 5.5+

import Foundation
import Combine

// Relative imports
import "../Core/Protocols/ViewModelProtocol"
import "../Models/Account"
import "../Models/Transaction"
import "../Mocks/MockAccountService"
import "../Mocks/MockTransactionService"

// MARK: - Human Tasks
// 1. Verify refresh interval with product team for optimal user experience
// 2. Add unit tests for error handling scenarios
// 3. Review memory management with tech lead for subscription handling

/// ViewModel responsible for managing the dashboard screen's data and business logic
/// Addresses requirements:
/// - Core Features - Dashboard (Technical Specification/8.1.1 Mobile Navigation Structure/Dashboard)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
@MainActor
final class DashboardViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var recentTransactions: [Transaction] = []
    @Published private(set) var totalBalance: Double = 0.0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    
    var cancellables = Set<AnyCancellable>()
    private let accountService: MockAccountService
    private let transactionService: MockTransactionService
    
    // MARK: - Initialization
    
    init(accountService: MockAccountService, transactionService: MockTransactionService) {
        self.accountService = accountService
        self.transactionService = transactionService
        
        // Set up account update subscription
        accountService.accountUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedAccount in
                self?.handleAccountUpdate(updatedAccount)
            }
            .store(in: &cancellables)
        
        // Perform initial data fetch
        initialize()
    }
    
    // MARK: - Public Methods
    
    func initialize() {
        Task {
            await refreshData()
        }
    }
    
    /// Refreshes all dashboard data
    /// - Returns: Void
    @MainActor
    func refreshData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch accounts
            let fetchedAccounts = try await accountService.fetchAccounts()
            self.accounts = fetchedAccounts
            
            // Calculate total balance
            calculateTotalBalance()
            
            // Fetch recent transactions using the first account ID
            if let firstAccountId = fetchedAccounts.first?.id {
                let transactionsPublisher = transactionService.fetchTransactions(accountId: firstAccountId)
                
                try await withCheckedThrowingContinuation { continuation in
                    transactionsPublisher
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { completion in
                                switch completion {
                                case .finished:
                                    continuation.resume()
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                }
                            },
                            receiveValue: { [weak self] transactions in
                                self?.recentTransactions = transactions
                            }
                        )
                        .store(in: &cancellables)
                }
            }
        } catch {
            errorMessage = "Failed to refresh dashboard data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// Calculates the total balance across all accounts
    private func calculateTotalBalance() {
        let total = accounts.reduce(0.0) { $0 + $1.balance }
        totalBalance = total
    }
    
    /// Handles updates to individual accounts
    /// - Parameter updatedAccount: The account that was updated
    private func handleAccountUpdate(_ updatedAccount: Account) {
        if let index = accounts.firstIndex(where: { $0.id == updatedAccount.id }) {
            accounts[index] = updatedAccount
            calculateTotalBalance()
        }
    }
}

// MARK: - ViewModelProtocol Conformance

extension DashboardViewModel {
    var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    var errorMessagePublisher: Published<String?>.Publisher { $errorMessage }
}