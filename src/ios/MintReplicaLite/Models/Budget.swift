// Foundation v5.5+
import Foundation

// Relative imports for extensions
import "../Core/Extensions/Double+Extensions"
import "../Core/Extensions/Date+Extensions"

// MARK: - Human Tasks
// 1. Verify budget period calculations with different timezones
// 2. Add unit tests for edge cases in budget progress calculations
// 3. Test currency formatting with various locales
// 4. Validate date handling around month/year boundaries

/// Represents different types of budget periods supported by the application
/// Addresses requirement: Budget Period Management (Technical Specification/8.1.4 Budget Creation/Edit)
@frozen
public enum BudgetPeriod: String, Codable {
    case weekly
    case monthly
    case custom
}

/// Core budget model representing budget configurations and tracking
/// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
@frozen
public class Budget: Codable {
    // MARK: - Properties
    
    public let id: String
    public let name: String
    public let amount: Double
    public let category: String
    public let period: BudgetPeriod
    public let startDate: Date
    public let endDate: Date
    public var spent: Double
    public var isActive: Bool
    
    // MARK: - Initialization
    
    /// Initializes a new Budget instance with validation
    /// Addresses requirement: Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
    public init(id: String,
               name: String,
               amount: Double,
               category: String,
               period: BudgetPeriod,
               startDate: Date,
               endDate: Date,
               spent: Double = 0.0,
               isActive: Bool = true) throws {
        
        // Validate amount
        guard amount > 0 else {
            throw NSError(domain: "Budget", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Budget amount must be greater than zero"])
        }
        
        // Validate dates
        guard endDate > startDate else {
            throw NSError(domain: "Budget", code: 1002, userInfo: [NSLocalizedDescriptionKey: "End date must be after start date"])
        }
        
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.period = period
        
        // Set period-specific dates
        switch period {
        case .monthly:
            self.startDate = startDate.startOfMonth()
            self.endDate = startDate.endOfMonth()
        case .weekly:
            self.startDate = startDate.startOfWeek()
            self.endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate.startOfWeek())!
        case .custom:
            self.startDate = startDate
            self.endDate = endDate
        }
        
        self.spent = spent
        self.isActive = isActive
    }
    
    // MARK: - Formatting Methods
    
    /// Returns the budget amount as a formatted currency string
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    public func formattedAmount() -> String {
        return amount.toCurrency()
    }
    
    /// Returns the spent amount as a formatted currency string
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    public func formattedSpent() -> String {
        return spent.toCurrency()
    }
    
    /// Calculates the percentage of budget spent
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    public func spentPercentage() -> Double {
        guard amount > 0 else { return 0 }
        let percentage = (spent / amount) * 100
        return min(percentage, 100) // Cap at 100% even if overspent
    }
    
    /// Returns the budget progress as a formatted percentage string
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    public func formattedProgress() -> String {
        return spentPercentage().toPercentage()
    }
    
    /// Checks if spending has exceeded budget amount
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
    public func isOverBudget() -> Bool {
        return spent > amount
    }
}