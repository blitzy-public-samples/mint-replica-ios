// Foundation v5.5+
import Foundation
// Combine v5.5+
import Combine

// Relative imports
import "../Models/Account"
import "../Core/Utilities/MockDataGenerator"

// MARK: - Human Tasks
// 1. Verify mock network delay duration with QA team
// 2. Adjust error simulation frequency based on testing needs
// 3. Add more edge cases for error simulation
// 4. Consider adding mock institution-specific error scenarios

/// Mock implementation of account service that simulates network operations and error scenarios
/// Addresses requirement: Financial Account Integration - Technical Specification/1.2 Scope/Core Features
/// Addresses requirement: Mock Implementation - Technical Specification/Constraints/3. Generate Only UI and ViewModel
@MainActor
public final class MockAccountService {
    // MARK: - Properties
    
    private var accounts: [Account]
    public let accountUpdateSubject: PassthroughSubject<Account, Never>
    private let mockNetworkDelay: TimeInterval
    
    // MARK: - Error Types
    
    private enum MockError: Error {
        case networkError
        case accountNotFound
        case invalidInstitution
    }
    
    // MARK: - Initialization
    
    /// Initializes the mock service with sample data and configurable network delay
    /// - Parameter networkDelay: Optional delay duration to simulate network latency (default: 1.0 seconds)
    public init(networkDelay: TimeInterval? = nil) {
        self.accounts = []
        self.accountUpdateSubject = PassthroughSubject<Account, Never>()
        self.mockNetworkDelay = networkDelay ?? 1.0
        
        // Generate initial mock accounts
        self.accounts = MockDataGenerator.generateMockAccounts(count: 5)
    }
    
    // MARK: - Private Methods
    
    /// Simulates network delay and potentially throws an error
    /// - Parameter errorProbability: Probability of error occurrence (0.0 to 1.0)
    private func simulateNetworkConditions(errorProbability: Double = 0.1) async throws {
        // Simulate network latency
        try await Task.sleep(nanoseconds: UInt64(mockNetworkDelay * 1_000_000_000))
        
        // Randomly simulate network error
        if Double.random(in: 0...1) < errorProbability {
            throw MockError.networkError
        }
    }
    
    // MARK: - Public Methods
    
    /// Simulates fetching all accounts with network delay
    /// - Returns: Array of mock accounts
    /// - Throws: MockError for simulated network failures
    public func fetchAccounts() async throws -> [Account] {
        try await simulateNetworkConditions()
        return accounts
    }
    
    /// Simulates fetching a single account by ID
    /// - Parameter id: Account identifier
    /// - Returns: Optional account matching the ID
    /// - Throws: MockError for simulated network failures or when account is not found
    public func getAccount(id: String) async throws -> Account? {
        try await simulateNetworkConditions()
        return accounts.first { $0.id == id }
    }
    
    /// Simulates linking a new financial account
    /// - Parameters:
    ///   - institutionId: Financial institution identifier
    ///   - type: Type of account to link
    /// - Returns: Newly created mock account
    /// - Throws: MockError for simulated network failures or invalid institution
    public func linkAccount(institutionId: String, type: AccountType) async throws -> Account {
        try await simulateNetworkConditions()
        
        // Create new mock account
        let newAccount = Account(
            id: UUID().uuidString,
            institutionId: institutionId,
            accountType: type,
            balance: Double.random(in: 1000...50000),
            currency: "USD",
            lastSynced: Date(),
            isActive: true
        )
        
        accounts.append(newAccount)
        accountUpdateSubject.send(newAccount)
        
        return newAccount
    }
    
    /// Simulates unlinking an existing account
    /// - Parameter id: Account identifier to unlink
    /// - Returns: Success status of the operation
    /// - Throws: MockError for simulated network failures
    public func unlinkAccount(id: String) async throws -> Bool {
        try await simulateNetworkConditions()
        
        if let index = accounts.firstIndex(where: { $0.id == id }) {
            let removedAccount = accounts.remove(at: index)
            accountUpdateSubject.send(removedAccount)
            return true
        }
        
        return false
    }
    
    /// Simulates refreshing account data with updated balance
    /// - Parameter id: Account identifier to refresh
    /// - Returns: Updated account with new balance
    /// - Throws: MockError for simulated network failures or when account is not found
    public func refreshAccount(id: String) async throws -> Account {
        try await simulateNetworkConditions()
        
        guard let index = accounts.firstIndex(where: { $0.id == id }) else {
            throw MockError.accountNotFound
        }
        
        // Update account with new random balance
        let currentBalance = accounts[index].balance
        let variationPercentage = Double.random(in: -0.05...0.05) // ±5% variation
        let newBalance = currentBalance * (1 + variationPercentage)
        
        accounts[index].updateBalance(newBalance)
        accountUpdateSubject.send(accounts[index])
        
        return accounts[index]
    }
}