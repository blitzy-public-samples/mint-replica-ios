// Foundation v5.5+
import Foundation
// SwiftUI v5.5+
import SwiftUI

// MARK: - Human Tasks
// 1. Verify account balance validation logic with finance team
// 2. Add unit tests for currency formatting edge cases
// 3. Test date formatting across different timezones

/// Represents different types of financial accounts supported by the app
/// Addresses requirement: Account Data Structure - Technical Specification/8.3.2 API Data Models
@frozen
public enum AccountType: String, Codable {
    case checking
    case savings
    case investment
    case credit
}

/// Model representing a financial account with its properties and formatting capabilities
/// Addresses requirement: Financial Account Integration - Technical Specification/1.2 Scope/Core Features
/// Addresses requirement: Account Data Structure - Technical Specification/8.3.2 API Data Models
@frozen
public class Account: Identifiable, Codable {
    // MARK: - Properties
    public let id: String
    public let institutionId: String
    public let accountType: AccountType
    public private(set) var balance: Double
    public let currency: String
    public private(set) var lastSynced: Date
    public var isActive: Bool
    
    // MARK: - Initialization
    
    /// Initializes a new Account instance with the required properties
    /// - Parameters:
    ///   - id: Unique identifier for the account
    ///   - institutionId: Identifier of the associated financial institution
    ///   - accountType: Type of the financial account
    ///   - balance: Current balance of the account
    ///   - currency: Currency code for the account (e.g., "USD")
    ///   - lastSynced: Timestamp of the last successful sync
    ///   - isActive: Flag indicating if the account is active
    public init(
        id: String,
        institutionId: String,
        accountType: AccountType,
        balance: Double,
        currency: String,
        lastSynced: Date,
        isActive: Bool = true
    ) {
        precondition(!id.isEmpty, "Account ID cannot be empty")
        precondition(!institutionId.isEmpty, "Institution ID cannot be empty")
        precondition(!currency.isEmpty, "Currency code cannot be empty")
        
        self.id = id
        self.institutionId = institutionId
        self.accountType = accountType
        self.balance = balance
        self.currency = currency
        self.lastSynced = lastSynced
        self.isActive = isActive
    }
    
    // MARK: - Public Methods
    
    /// Updates the account balance and last synced timestamp
    /// - Parameter newBalance: New balance value to set
    /// - Throws: InvalidBalanceError if the new balance is negative for non-credit accounts
    public func updateBalance(_ newBalance: Double) {
        // Credit accounts can have negative balances
        if accountType != .credit {
            precondition(newBalance >= 0, "Balance cannot be negative for non-credit accounts")
        }
        
        self.balance = newBalance
        self.lastSynced = Date()
    }
    
    /// Returns the account balance formatted as a currency string
    /// - Returns: Formatted balance with currency symbol and proper decimal places
    public func formattedBalance() -> String {
        return balance.toCurrency()
    }
    
    /// Returns the last synced date in human-readable format
    /// - Returns: Formatted date string using the app's standard date format
    public func formattedLastSynced() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormat.displayFormat
        return dateFormatter.string(from: lastSynced)
    }
}