// Foundation v5.5+
import Foundation
import Combine

// Relative imports
import "../Models/Transaction"
import "../Core/Utilities/MockDataGenerator"

// MARK: - Human Tasks
/*
 * 1. Verify artificial delay durations with UX team for optimal preview experience
 * 2. Add error simulation scenarios for testing error handling
 * 3. Consider adding network condition simulation (slow/fast responses)
 */

/// Mock service class that provides simulated transaction operations for development and preview
/// Addresses requirements:
/// - Transaction Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Transaction Categorization (Technical Specification/1.2 Scope/Core Features)
/// - Mock Implementation (Technical Specification/Constraints/3. Generate Only UI and ViewModel)
@MainActor
public final class MockTransactionService {
    // MARK: - Properties
    
    /// Cached transactions for in-memory operations
    private var cachedTransactions: [Transaction]
    
    /// Subject for broadcasting transaction updates
    private let transactionsSubject: PassthroughSubject<[Transaction], Error>
    
    // MARK: - Initialization
    
    /// Initializes the mock service with initial cached data
    public init() {
        self.cachedTransactions = []
        self.transactionsSubject = PassthroughSubject<[Transaction], Error>()
        
        // Generate initial mock data
        self.cachedTransactions = MockDataGenerator.generateMockTransactions(
            count: 20,
            accountId: "default"
        )
    }
    
    // MARK: - Public Methods
    
    /// Fetches mock transactions for a given account with artificial delay
    /// - Parameter accountId: Account identifier to fetch transactions for
    /// - Returns: Publisher that emits mock transactions after delay
    public func fetchTransactions(accountId: String) -> AnyPublisher<[Transaction], Error> {
        // Generate new mock transactions
        let newTransactions = MockDataGenerator.generateMockTransactions(
            count: Int.random(in: 10...20),
            accountId: accountId
        )
        
        // Update cached transactions
        cachedTransactions = newTransactions
        
        // Emit through subject
        transactionsSubject.send(cachedTransactions)
        
        // Return with artificial delay
        return Just(cachedTransactions)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Searches mock transactions using provided query string
    /// - Parameter query: Search query string
    /// - Returns: Publisher that emits filtered transactions
    public func searchTransactions(query: String) -> AnyPublisher<[Transaction], Error> {
        let lowercaseQuery = query.lowercased()
        
        let filteredTransactions = cachedTransactions.filter { transaction in
            transaction.description.lowercased().contains(lowercaseQuery) ||
            (transaction.merchantName?.lowercased().contains(lowercaseQuery) ?? false)
        }
        
        return Just(filteredTransactions)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Updates the category of a mock transaction by ID
    /// - Parameters:
    ///   - transactionId: ID of the transaction to update
    ///   - newCategory: New category to assign
    /// - Returns: Publisher that emits updated transaction
    public func categorizeTransaction(
        transactionId: String,
        newCategory: String
    ) -> AnyPublisher<Transaction, Error> {
        guard let index = cachedTransactions.firstIndex(where: { $0.id == transactionId }) else {
            return Fail(error: NSError(domain: "MockTransactionService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Transaction not found"
            ]))
            .eraseToAnyPublisher()
        }
        
        // Create updated transaction
        let updatedTransaction = Transaction(
            id: cachedTransactions[index].id,
            accountId: cachedTransactions[index].accountId,
            amount: cachedTransactions[index].amount,
            date: cachedTransactions[index].date,
            description: cachedTransactions[index].description,
            category: newCategory,
            pending: cachedTransactions[index].pending,
            merchantName: cachedTransactions[index].merchantName,
            notes: cachedTransactions[index].notes
        )
        
        // Update cached transactions
        cachedTransactions[index] = updatedTransaction
        
        // Emit updated list
        transactionsSubject.send(cachedTransactions)
        
        return Just(updatedTransaction)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Adds or updates a note on a mock transaction
    /// - Parameters:
    ///   - transactionId: ID of the transaction to update
    ///   - note: Note text to add or update
    /// - Returns: Publisher that emits updated transaction
    public func addNote(
        transactionId: String,
        note: String
    ) -> AnyPublisher<Transaction, Error> {
        guard let index = cachedTransactions.firstIndex(where: { $0.id == transactionId }) else {
            return Fail(error: NSError(domain: "MockTransactionService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Transaction not found"
            ]))
            .eraseToAnyPublisher()
        }
        
        // Create updated transaction
        let updatedTransaction = Transaction(
            id: cachedTransactions[index].id,
            accountId: cachedTransactions[index].accountId,
            amount: cachedTransactions[index].amount,
            date: cachedTransactions[index].date,
            description: cachedTransactions[index].description,
            category: cachedTransactions[index].category,
            pending: cachedTransactions[index].pending,
            merchantName: cachedTransactions[index].merchantName,
            notes: note
        )
        
        // Update cached transactions
        cachedTransactions[index] = updatedTransaction
        
        // Emit updated list
        transactionsSubject.send(cachedTransactions)
        
        return Just(updatedTransaction)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}