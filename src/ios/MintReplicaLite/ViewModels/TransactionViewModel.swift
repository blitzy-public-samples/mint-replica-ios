// External dependencies versions:
// Foundation: 5.5+
// Combine: 5.5+
// SwiftUI: 5.5+

import Foundation
import Combine
import SwiftUI

// Relative imports
import "../Models/Transaction"
import "../Mocks/MockTransactionService"
import "../Core/Protocols/ViewModelProtocol"

// MARK: - Human Tasks
/*
 * 1. Verify debounce time for search with UX team
 * 2. Add unit tests for transaction state management
 * 3. Review error handling scenarios with product team
 */

/// ViewModel responsible for managing transaction-related business logic and state
/// Requirements addressed:
/// - Transaction Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Transaction Categorization (Technical Specification/1.2 Scope/Core Features)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
@MainActor
final class TransactionViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var searchQuery = ""
    
    // MARK: - Protocol Properties
    
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Publishers
    
    var isLoading: Published<Bool>.Publisher { $isLoading }
    var errorMessage: Published<String?>.Publisher { $errorMessage }
    
    // MARK: - Private Properties
    
    private let transactionService: MockTransactionService
    private let accountId: String
    
    // MARK: - Initialization
    
    init(accountId: String, transactionService: MockTransactionService) {
        self.accountId = accountId
        self.transactionService = transactionService
        initialize()
    }
    
    // MARK: - ViewModelProtocol Implementation
    
    func initialize() {
        // Set up search query debounce
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                if !query.isEmpty {
                    self.searchTransactions(query: query)
                } else {
                    self.loadTransactions()
                }
            }
            .store(in: &cancellables)
        
        // Load initial transactions
        loadTransactions()
    }
    
    // MARK: - Public Methods
    
    /// Loads transactions for the current account
    func loadTransactions() {
        isLoading = true
        errorMessage = nil
        
        transactionService.fetchTransactions(accountId: accountId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] transactions in
                guard let self = self else { return }
                self.transactions = transactions
            }
            .store(in: &cancellables)
    }
    
    /// Searches transactions based on the provided query
    /// - Parameter query: Search query string
    func searchTransactions(query: String) {
        isLoading = true
        
        transactionService.searchTransactions(query: query)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] transactions in
                guard let self = self else { return }
                self.transactions = transactions
            }
            .store(in: &cancellables)
    }
    
    /// Updates the category of a transaction
    /// - Parameters:
    ///   - transactionId: ID of the transaction to update
    ///   - category: New category to assign
    func categorizeTransaction(transactionId: String, category: String) {
        transactionService.categorizeTransaction(transactionId: transactionId, newCategory: category)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updatedTransaction in
                guard let self = self else { return }
                if let index = self.transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
                    self.transactions[index] = updatedTransaction
                }
            }
            .store(in: &cancellables)
    }
    
    /// Adds or updates a note on a transaction
    /// - Parameters:
    ///   - transactionId: ID of the transaction to update
    ///   - note: Note text to add or update
    func addNote(transactionId: String, note: String) {
        transactionService.addNote(transactionId: transactionId, note: note)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updatedTransaction in
                guard let self = self else { return }
                if let index = self.transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
                    self.transactions[index] = updatedTransaction
                }
            }
            .store(in: &cancellables)
    }
}