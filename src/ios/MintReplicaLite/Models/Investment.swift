// Foundation v5.5+
import Foundation

// Relative import for currency and return formatting extensions
import Core.Extensions.Double_Extensions

// MARK: - Human Tasks
// 1. Verify asset class categories match backend requirements
// 2. Add unit tests for edge cases with extremely large values
// 3. Review validation rules with product team
// 4. Consider adding support for fractional shares validation

/// A frozen class representing an investment holding in a user's portfolio
/// Addresses requirement: Investment Portfolio Tracking - Technical Specification/1.2 Scope/Core Features
/// Addresses requirement: Investment Dashboard Data Model - Technical Specification/8.1.5 Investment Dashboard
@frozen
public class Investment: Codable {
    
    // MARK: - Properties
    
    public let id: String
    public let accountId: String
    public let symbol: String
    public let name: String
    public let quantity: Double
    public let costBasis: Double
    public let currentPrice: Double
    public let lastUpdated: Date
    public let assetClass: String
    
    // MARK: - Asset Class Constants
    
    private enum AssetClasses {
        static let stocks = "stocks"
        static let bonds = "bonds"
        static let mutualFunds = "mutual_funds"
        static let etfs = "etfs"
        static let crypto = "crypto"
        static let cash = "cash"
        
        static let validCategories: Set<String> = [
            stocks, bonds, mutualFunds, etfs, crypto, cash
        ]
    }
    
    // MARK: - Initialization
    
    /// Initialize a new Investment instance with validation
    /// - Parameters:
    ///   - id: Unique identifier for the investment
    ///   - accountId: Associated account identifier
    ///   - symbol: Trading symbol/ticker
    ///   - name: Display name of the investment
    ///   - quantity: Number of shares/units held
    ///   - costBasis: Original cost per share/unit
    ///   - currentPrice: Current market price per share/unit
    ///   - lastUpdated: Timestamp of last price update
    ///   - assetClass: Category of the investment
    public init(id: String, accountId: String, symbol: String, name: String,
                quantity: Double, costBasis: Double, currentPrice: Double,
                lastUpdated: Date, assetClass: String) throws {
        // Validate id and accountId
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw InvestmentError.invalidId
        }
        guard !accountId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw InvestmentError.invalidAccountId
        }
        
        // Validate symbol
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSymbol.isEmpty && trimmedSymbol.range(of: "^[A-Z0-9.-]+$",
                                                           options: .regularExpression) != nil else {
            throw InvestmentError.invalidSymbol
        }
        
        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw InvestmentError.invalidName
        }
        
        // Validate numeric values
        guard quantity >= 0 else {
            throw InvestmentError.invalidQuantity
        }
        guard costBasis >= 0 else {
            throw InvestmentError.invalidCostBasis
        }
        guard currentPrice >= 0 else {
            throw InvestmentError.invalidCurrentPrice
        }
        
        // Validate asset class
        guard AssetClasses.validCategories.contains(assetClass.lowercased()) else {
            throw InvestmentError.invalidAssetClass
        }
        
        self.id = id
        self.accountId = accountId
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.costBasis = costBasis
        self.currentPrice = currentPrice
        self.lastUpdated = lastUpdated
        self.assetClass = assetClass.lowercased()
    }
    
    // MARK: - Value Calculations
    
    /// Calculate the current total value of the investment
    /// - Returns: Current value calculated as quantity * currentPrice
    public func getCurrentValue() -> Double {
        return quantity * currentPrice
    }
    
    /// Calculate the total return amount (gain/loss)
    /// - Returns: Total return amount (current value - cost basis)
    public func getReturnAmount() -> Double {
        let totalCostBasis = quantity * costBasis
        return getCurrentValue() - totalCostBasis
    }
    
    /// Calculate the return percentage
    /// - Returns: Return percentage as a decimal
    public func getReturnPercentage() -> Double {
        let totalCostBasis = quantity * costBasis
        guard totalCostBasis > 0 else { return 0.0 }
        return getReturnAmount() / totalCostBasis
    }
    
    // MARK: - Formatted Values
    
    /// Get the current value formatted as currency
    /// - Returns: Formatted currency string using toCurrency extension
    public func getFormattedCurrentValue() -> String {
        return getCurrentValue().toCurrency()
    }
    
    /// Get the return percentage formatted with sign
    /// - Returns: Formatted return percentage using asInvestmentReturn extension
    public func getFormattedReturn() -> String {
        return getReturnPercentage().asInvestmentReturn()
    }
}

// MARK: - Investment Errors

/// Enumeration of possible investment validation errors
enum InvestmentError: Error {
    case invalidId
    case invalidAccountId
    case invalidSymbol
    case invalidName
    case invalidQuantity
    case invalidCostBasis
    case invalidCurrentPrice
    case invalidAssetClass
}