// Foundation v5.5+
import Foundation

// MARK: - Human Tasks
/*
 * 1. Verify transaction amount validation for different currencies and edge cases
 * 2. Add unit tests for date formatting across different locales
 * 3. Test transaction comparison with pending vs non-pending states
 */

// Relative imports for extensions
import "../Core/Extensions/Date+Extensions"
import "../Core/Extensions/Double+Extensions"

/// Core model representing a financial transaction in the MintReplicaLite app
/// Addresses requirements:
/// - Transaction Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Transaction Categorization (Technical Specification/1.2 Scope/Core Features)
/// - Transaction Processing (Technical Specification/6.2.2 Transaction Processing Flow)
@frozen
public struct Transaction: Codable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier for the transaction
    public let id: String
    
    /// Associated account identifier
    public let accountId: String
    
    /// Transaction amount (positive for credits, negative for debits)
    public let amount: Double
    
    /// Date when the transaction occurred
    public let date: Date
    
    /// Transaction description from financial institution
    public let description: String
    
    /// Transaction category for budget tracking
    public let category: String
    
    /// Indicates if transaction is pending or posted
    public let pending: Bool
    
    /// Optional merchant name for enhanced transaction details
    public let merchantName: String?
    
    /// Optional user-provided notes
    public let notes: String?
    
    // MARK: - Initialization
    
    /// Initializes a new Transaction instance with required and optional properties
    /// - Parameters:
    ///   - id: Unique transaction identifier
    ///   - accountId: Associated account identifier
    ///   - amount: Transaction amount
    ///   - date: Transaction date
    ///   - description: Transaction description
    ///   - category: Transaction category
    ///   - pending: Transaction pending status
    ///   - merchantName: Optional merchant name
    ///   - notes: Optional transaction notes
    public init(
        id: String,
        accountId: String,
        amount: Double,
        date: Date,
        description: String,
        category: String,
        pending: Bool,
        merchantName: String? = nil,
        notes: String? = nil
    ) {
        // Validate required string parameters are not empty
        precondition(!id.isEmpty, "Transaction ID cannot be empty")
        precondition(!accountId.isEmpty, "Account ID cannot be empty")
        precondition(!description.isEmpty, "Transaction description cannot be empty")
        precondition(!category.isEmpty, "Transaction category cannot be empty")
        
        self.id = id
        self.accountId = accountId
        self.amount = amount
        self.date = date
        self.description = description
        self.category = category
        self.pending = pending
        self.merchantName = merchantName
        self.notes = notes
    }
    
    // MARK: - Formatting
    
    /// Returns the transaction amount formatted as currency string
    /// - Returns: Formatted currency string with proper sign and decimals
    public func formattedAmount() -> String {
        return amount.toCurrency()
    }
    
    /// Returns the transaction date formatted for display
    /// - Returns: Formatted date string in user's locale
    public func formattedDate() -> String {
        return date.formattedForDisplay()
    }
}