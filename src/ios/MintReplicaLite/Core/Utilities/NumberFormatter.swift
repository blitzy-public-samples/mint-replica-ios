// Foundation v5.5+
import Foundation

/// Relative import for notification constants
import Constants

// MARK: - Human Tasks
// 1. Ensure device locale settings are properly configured for testing currency formatting
// 2. Verify number formatting behavior with various regional settings
// 3. Add unit tests to verify formatting edge cases (very large numbers, negative values)

/// NumberFormatterUtility: A singleton class providing standardized number formatting across the app
/// Addresses requirement: Financial Data Display - Technical Specification/8.1.2 Main Dashboard
/// Addresses requirement: Investment Portfolio Display - Technical Specification/8.1.5 Investment Dashboard
final class NumberFormatterUtility {
    
    // MARK: - Singleton Instance
    
    /// Shared instance of the formatter utility
    static let shared = NumberFormatterUtility()
    
    // MARK: - Properties
    
    /// Formatter configured for currency values
    private let currencyFormatter: NumberFormatter
    
    /// Formatter configured for percentage values
    private let percentFormatter: NumberFormatter
    
    /// Formatter configured for compact number display
    private let compactFormatter: NumberFormatter
    
    // MARK: - Initialization
    
    private init() {
        // Initialize currency formatter
        currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        currencyFormatter.maximumFractionDigits = 2
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.usesGroupingSeparator = true
        
        // Initialize percentage formatter
        percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 1
        percentFormatter.minimumFractionDigits = 0
        percentFormatter.multiplier = 1 // Values are expected in decimal form
        
        // Initialize compact formatter
        compactFormatter = NumberFormatter()
        compactFormatter.numberStyle = .decimal
        compactFormatter.usesGroupingSeparator = true
        if #available(iOS 15.0, *) {
            compactFormatter.notation = .compactWithMaximumSignificantDigits(1)
        }
    }
    
    // MARK: - Public Methods
    
    /// Formats a numeric value as currency with the appropriate symbol and decimal places
    /// - Parameter amount: The numeric value to format
    /// - Returns: Formatted currency string with appropriate symbol and decimals (e.g., $1,234.56)
    func formatCurrency(_ amount: Double) -> String {
        guard let formattedString = currencyFormatter.string(from: NSNumber(value: amount)) else {
            return ""
        }
        return formattedString
    }
    
    /// Formats a numeric value as a percentage
    /// - Parameter value: The decimal value to format (e.g., 0.425 for 42.5%)
    /// - Returns: Formatted percentage string with % symbol (e.g., 42.5%)
    func formatPercentage(_ value: Double) -> String {
        // Special handling for budget alert threshold comparison
        if value == NotificationConstants.budgetAlertThreshold {
            return percentFormatter.string(from: NSNumber(value: value)) ?? "85%"
        }
        
        guard let formattedString = percentFormatter.string(from: NSNumber(value: value)) else {
            return ""
        }
        return formattedString
    }
    
    /// Formats large numbers in a compact form for readable display
    /// - Parameter number: The numeric value to format
    /// - Returns: Compact formatted number string (e.g., 1.2M, 450K)
    func formatCompactNumber(_ number: Double) -> String {
        if #available(iOS 15.0, *) {
            guard let formattedString = compactFormatter.string(from: NSNumber(value: number)) else {
                return ""
            }
            return formattedString
        } else {
            // Fallback for iOS versions < 15.0
            let suffixes = ["", "K", "M", "B", "T"]
            var num = abs(number)
            var index = 0
            
            while num >= 1000 && index < suffixes.count - 1 {
                num /= 1000
                index += 1
            }
            
            let isNegative = number < 0 ? "-" : ""
            return String(format: "\(isNegative)%.1f%@", num, suffixes[index])
        }
    }
}