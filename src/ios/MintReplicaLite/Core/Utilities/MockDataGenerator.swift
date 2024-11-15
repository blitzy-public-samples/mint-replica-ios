// Foundation v5.5+
import Foundation

// Relative imports for models
import "../../Models/Account"
import "../../Models/Transaction"
import "../../Models/Budget"

// MARK: - Human Tasks
// 1. Verify mock data ranges and values with product team
// 2. Add more diverse test data for edge cases
// 3. Consider adding localization support for mock merchant names
// 4. Add more varied transaction categories based on business requirements

/// Utility class that generates mock data for testing and preview purposes
/// Addresses requirement: Preview Content (Technical Specification/Constraints/3. Generate Only UI and ViewModel)
public final class MockDataGenerator {
    
    // MARK: - Mock Data Arrays
    
    private static let mockMerchants = [
        "Whole Foods Market",
        "Amazon",
        "Target",
        "Starbucks",
        "Apple Store",
        "Chevron",
        "Netflix",
        "Uber",
        "Home Depot",
        "Walmart"
    ]
    
    private static let mockCategories = [
        "Groceries",
        "Shopping",
        "Entertainment",
        "Transportation",
        "Utilities",
        "Dining",
        "Healthcare",
        "Travel",
        "Education",
        "Housing"
    ]
    
    private static let mockInstitutions = [
        "Chase Bank",
        "Bank of America",
        "Wells Fargo",
        "Citibank",
        "Capital One",
        "American Express",
        "Fidelity",
        "Charles Schwab",
        "Vanguard",
        "TD Bank"
    ]
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer to prevent instantiation
    }
    
    // MARK: - Mock Data Generation Methods
    
    /// Generates an array of mock Account instances with realistic data
    /// - Parameter count: Number of mock accounts to generate
    /// - Returns: Array of mock Account instances
    public static func generateMockAccounts(count: Int) -> [Account] {
        var accounts: [Account] = []
        
        for index in 0..<count {
            let accountType: AccountType = [.checking, .savings, .investment, .credit][index % 4]
            let balance: Double
            
            // Set realistic balances based on account type
            switch accountType {
            case .checking:
                balance = Double.random(in: 1000...15000)
            case .savings:
                balance = Double.random(in: 5000...50000)
            case .investment:
                balance = Double.random(in: 10000...250000)
            case .credit:
                balance = Double.random(in: -5000...0)
            }
            
            let lastSynced = Calendar.current.date(
                byAdding: .day,
                value: -Int.random(in: 0...7),
                to: Date()
            ) ?? Date()
            
            let account = Account(
                id: UUID().uuidString,
                institutionId: mockInstitutions[index % mockInstitutions.count],
                accountType: accountType,
                balance: balance,
                currency: "USD",
                lastSynced: lastSynced,
                isActive: true
            )
            
            accounts.append(account)
        }
        
        return accounts
    }
    
    /// Generates an array of mock Transaction instances with realistic data
    /// - Parameters:
    ///   - count: Number of mock transactions to generate
    ///   - accountId: Account ID to associate with transactions
    /// - Returns: Array of mock Transaction instances
    public static func generateMockTransactions(count: Int, accountId: String) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for _ in 0..<count {
            let isDebit = Double.random(in: 0...1) < 0.8 // 80% chance of debit
            let amount = isDebit ?
                -Double.random(in: 5...500) :
                Double.random(in: 100...5000)
            
            let daysAgo = Int.random(in: 0...90)
            let date = Calendar.current.date(
                byAdding: .day,
                value: -daysAgo,
                to: Date()
            ) ?? Date()
            
            let merchantIndex = Int.random(in: 0..<mockMerchants.count)
            let categoryIndex = Int.random(in: 0..<mockCategories.count)
            
            let transaction = Transaction(
                id: UUID().uuidString,
                accountId: accountId,
                amount: amount,
                date: date,
                description: "\(mockMerchants[merchantIndex]) Transaction",
                category: mockCategories[categoryIndex],
                pending: Double.random(in: 0...1) < 0.1, // 10% chance of pending
                merchantName: mockMerchants[merchantIndex]
            )
            
            transactions.append(transaction)
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    /// Generates a mock Budget instance with realistic categories and amounts
    /// - Returns: A mock Budget instance
    public static func generateMockBudget() -> Budget? {
        let category = mockCategories[Int.random(in: 0..<mockCategories.count)]
        
        // Set realistic budget amount based on category
        let amount: Double
        switch category {
        case "Housing":
            amount = Double.random(in: 1500...3000)
        case "Groceries":
            amount = Double.random(in: 400...800)
        case "Transportation":
            amount = Double.random(in: 200...500)
        case "Entertainment":
            amount = Double.random(in: 100...300)
        default:
            amount = Double.random(in: 200...1000)
        }
        
        let startDate = Date().startOfMonth()
        let endDate = Date().endOfMonth()
        let spent = amount * Double.random(in: 0...1.2) // 0-120% of budget
        
        do {
            return try Budget(
                id: UUID().uuidString,
                name: "\(category) Budget",
                amount: amount,
                category: category,
                period: .monthly,
                startDate: startDate,
                endDate: endDate,
                spent: spent,
                isActive: true
            )
        } catch {
            return nil
        }
    }
}