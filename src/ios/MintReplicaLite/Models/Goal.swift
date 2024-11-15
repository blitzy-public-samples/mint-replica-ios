// Foundation v5.5+
import Foundation

// Relative imports for formatting utilities
import "../Core/Extensions/Date+Extensions"
import "../Core/Extensions/Double+Extensions"

// MARK: - Human Tasks
/*
 1. Add validation for edge cases in goal amount calculations
 2. Implement unit tests for progress calculation and formatting
 3. Verify date handling across different timezones
 4. Add data persistence implementation
*/

/// Represents a financial goal category
@frozen
enum GoalCategory: String, Codable {
    case savings
    case debt
    case investment
    case emergency
    case retirement
    case education
    case home
    case travel
    case other
}

/// A class representing a financial goal with tracking capabilities
/// Addresses requirement: Financial Goal Setting (Technical Specification/1.1 System Overview/Core Features)
@frozen
class Goal: Codable {
    // MARK: - Properties
    
    let id: String
    let name: String
    let description: String
    let targetAmount: Double
    var currentAmount: Double
    let targetDate: Date
    let createdDate: Date
    var isCompleted: Bool
    let category: GoalCategory
    
    // MARK: - Initialization
    
    /// Initializes a new Goal instance with required properties
    /// - Parameters:
    ///   - id: Unique identifier for the goal
    ///   - name: Display name of the goal
    ///   - description: Detailed description of the goal
    ///   - targetAmount: Target amount to achieve
    ///   - currentAmount: Current progress amount
    ///   - targetDate: Target date to achieve the goal
    ///   - category: Category of the financial goal
    init(id: String,
         name: String,
         description: String,
         targetAmount: Double,
         currentAmount: Double,
         targetDate: Date,
         category: GoalCategory) throws {
        
        // Validate target amount
        guard targetAmount > 0 else {
            throw GoalError.invalidTargetAmount
        }
        
        // Validate current amount
        guard currentAmount >= 0 else {
            throw GoalError.invalidCurrentAmount
        }
        
        // Validate target date
        guard targetDate > Date() else {
            throw GoalError.invalidTargetDate
        }
        
        self.id = id
        self.name = name
        self.description = description
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.category = category
        self.createdDate = Date()
        self.isCompleted = false
    }
    
    // MARK: - Progress Calculation
    
    /// Calculates the current progress towards the goal as a percentage
    /// Addresses requirement: Goal Progress Tracking (Technical Specification/8.1.2 Main Dashboard)
    func calculateProgress() -> Double {
        guard targetAmount > 0 else { return 0 }
        let progress = (currentAmount / targetAmount) * 100
        return min(max(progress, 0), 100)
    }
    
    // MARK: - Formatting Methods
    
    /// Returns the target amount formatted as currency
    func formattedTargetAmount() -> String {
        return targetAmount.toCurrency()
    }
    
    /// Returns the current amount formatted as currency
    func formattedCurrentAmount() -> String {
        return currentAmount.toCurrency()
    }
    
    /// Returns the progress formatted as a percentage
    func formattedProgress() -> String {
        return calculateProgress().toPercentage()
    }
    
    /// Returns the target date in display format
    func formattedTargetDate() -> String {
        return targetDate.formattedForDisplay()
    }
    
    // MARK: - Progress Update
    
    /// Updates the current amount and checks if goal is completed
    /// - Parameter newAmount: New current amount to set
    /// - Returns: Whether goal is now completed
    /// - Throws: GoalError if amount is invalid
    @discardableResult
    func updateProgress(_ newAmount: Double) throws -> Bool {
        guard newAmount >= 0 else {
            throw GoalError.invalidCurrentAmount
        }
        
        currentAmount = newAmount
        isCompleted = currentAmount >= targetAmount
        return isCompleted
    }
}

// MARK: - Error Handling

/// Errors that can occur when working with goals
enum GoalError: Error {
    case invalidTargetAmount
    case invalidCurrentAmount
    case invalidTargetDate
}