// Foundation v5.5+
import Foundation

// Relative imports for models
import "../Models/Account"
import "../Models/Transaction"
import "../Models/Budget"

// MARK: - Human Tasks
// 1. Verify mock data values with product team for realistic test scenarios
// 2. Add additional transaction categories if needed for testing
// 3. Validate currency formatting across different locales with mock data

// MARK: - Preview Data
/// Addresses requirement: SwiftUI Preview Support (Technical Specification/5.2.1 Mobile Applications)
/// Provides sample accounts for SwiftUI previews
public let previewAccounts: [Account] = generatePreviewAccounts()

/// Addresses requirement: SwiftUI Preview Support (Technical Specification/5.2.1 Mobile Applications)
/// Provides sample transactions for SwiftUI previews
public let previewTransactions: [Transaction] = generatePreviewTransactions()

/// Addresses requirement: SwiftUI Preview Support (Technical Specification/5.2.1 Mobile Applications)
/// Provides sample budgets for SwiftUI previews
public let previewBudgets: [Budget] = generatePreviewBudgets()

// MARK: - Generator Functions

/// Generates a set of sample accounts for SwiftUI previews
/// Addresses requirement: Mock Data Generation (Technical Specification/5.3.1 Frontend Technologies)
public func generatePreviewAccounts() -> [Account] {
    let now = Date()
    
    return [
        Account(
            id: "checking-001",
            institutionId: "chase-01",
            accountType: .checking,
            balance: 2500.00,
            currency: "USD",
            lastSynced: now.addingTimeInterval(-3600), // 1 hour ago
            isActive: true
        ),
        Account(
            id: "savings-001",
            institutionId: "chase-01",
            accountType: .savings,
            balance: 10000.00,
            currency: "USD",
            lastSynced: now.addingTimeInterval(-7200), // 2 hours ago
            isActive: true
        ),
        Account(
            id: "investment-001",
            institutionId: "fidelity-01",
            accountType: .investment,
            balance: 50000.00,
            currency: "USD",
            lastSynced: now.addingTimeInterval(-14400), // 4 hours ago
            isActive: true
        ),
        Account(
            id: "credit-001",
            institutionId: "amex-01",
            accountType: .credit,
            balance: -1500.00,
            currency: "USD",
            lastSynced: now.addingTimeInterval(-21600), // 6 hours ago
            isActive: true
        )
    ]
}

/// Generates a set of sample transactions for SwiftUI previews
/// Addresses requirement: Mock Data Generation (Technical Specification/5.3.1 Frontend Technologies)
public func generatePreviewTransactions() -> [Transaction] {
    let now = Date()
    let calendar = Calendar.current
    
    return [
        // Grocery transactions
        Transaction(
            id: "trans-001",
            accountId: "checking-001",
            amount: -156.78,
            date: calendar.date(byAdding: .day, value: -2, to: now)!,
            description: "Whole Foods Market",
            category: "Groceries",
            pending: false
        ),
        Transaction(
            id: "trans-002",
            accountId: "checking-001",
            amount: -82.45,
            date: calendar.date(byAdding: .day, value: -5, to: now)!,
            description: "Trader Joe's",
            category: "Groceries",
            pending: false
        ),
        
        // Utility bills
        Transaction(
            id: "trans-003",
            accountId: "checking-001",
            amount: -245.00,
            date: calendar.date(byAdding: .day, value: -3, to: now)!,
            description: "Electric Company",
            category: "Utilities",
            pending: false
        ),
        
        // Restaurant transactions
        Transaction(
            id: "trans-004",
            accountId: "credit-001",
            amount: -85.40,
            date: calendar.date(byAdding: .day, value: -1, to: now)!,
            description: "Local Restaurant",
            category: "Dining",
            pending: true
        ),
        Transaction(
            id: "trans-005",
            accountId: "credit-001",
            amount: -32.50,
            date: calendar.date(byAdding: .day, value: -4, to: now)!,
            description: "Coffee Shop",
            category: "Dining",
            pending: false
        ),
        
        // Shopping transactions
        Transaction(
            id: "trans-006",
            accountId: "credit-001",
            amount: -299.99,
            date: calendar.date(byAdding: .day, value: -7, to: now)!,
            description: "Department Store",
            category: "Shopping",
            pending: false
        ),
        Transaction(
            id: "trans-007",
            accountId: "credit-001",
            amount: -159.99,
            date: now,
            description: "Online Retailer",
            category: "Shopping",
            pending: true
        )
    ]
}

/// Generates a set of sample budgets for SwiftUI previews
/// Addresses requirement: Mock Data Generation (Technical Specification/5.3.1 Frontend Technologies)
public func generatePreviewBudgets() -> [Budget] {
    let now = Date()
    
    return try! [
        Budget(
            id: "budget-001",
            name: "Grocery Budget",
            amount: 600.00,
            category: "Groceries",
            period: .monthly,
            startDate: now,
            endDate: now,  // Will be calculated based on period
            spent: 239.23,
            isActive: true
        ),
        Budget(
            id: "budget-002",
            name: "Utilities",
            amount: 300.00,
            category: "Utilities",
            period: .monthly,
            startDate: now,
            endDate: now,  // Will be calculated based on period
            spent: 245.00,
            isActive: true
        ),
        Budget(
            id: "budget-003",
            name: "Dining Out",
            amount: 200.00,
            category: "Dining",
            period: .weekly,
            startDate: now,
            endDate: now,  // Will be calculated based on period
            spent: 117.90,
            isActive: true
        ),
        Budget(
            id: "budget-004",
            name: "Shopping",
            amount: 400.00,
            category: "Shopping",
            period: .monthly,
            startDate: now,
            endDate: now,  // Will be calculated based on period
            spent: 459.98,  // Over budget example
            isActive: true
        )
    ]
}