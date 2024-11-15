// Foundation v5.5+
import Foundation

// Relative import for number formatting utility
import Core.Utilities.NumberFormatter

// MARK: - Human Tasks
// 1. Verify currency formatting with different locales and edge cases
// 2. Add unit tests for investment return formatting with extreme values
// 3. Test compact currency formatting with large numbers (millions/billions)

/// Extension on Double providing financial formatting capabilities
/// Addresses requirement: Financial Data Display - Technical Specification/8.1.2 Main Dashboard
/// Addresses requirement: Investment Returns Display - Technical Specification/8.1.5 Investment Dashboard
extension Double {
    
    /// Formats the double value as a currency string using the app's centralized number formatter
    /// - Returns: Formatted currency string with proper symbol and decimal places (e.g., $1,234.56)
    func toCurrency() -> String {
        return NumberFormatterUtility.shared.formatCurrency(self)
    }
    
    /// Formats the double value as a compact currency string for large amounts
    /// - Returns: Compact formatted currency string (e.g., $1.2M, $450K)
    func toCompactCurrency() -> String {
        return NumberFormatterUtility.shared.formatCompactNumber(self)
    }
    
    /// Formats the double value as a percentage string
    /// - Parameter decimalPlaces: Number of decimal places to display
    /// - Returns: Formatted percentage string with % symbol (e.g., 42.5%)
    func toPercentage(decimalPlaces: Int = 1) -> String {
        let roundedValue = self.roundToDecimal(places: decimalPlaces)
        return NumberFormatterUtility.shared.formatPercentage(roundedValue)
    }
    
    /// Rounds the double value to specified number of decimal places
    /// - Parameter places: Number of decimal places to round to
    /// - Returns: Rounded double value
    func roundToDecimal(places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
    
    /// Formats the double value as an investment return percentage with sign
    /// - Returns: Formatted investment return string with + or - sign (e.g., +42.5%, -12.3%)
    func asInvestmentReturn() -> String {
        let roundedValue = self.roundToDecimal(places: 2)
        let percentageString = NumberFormatterUtility.shared.formatPercentage(roundedValue)
        
        // Add plus sign for positive values, negative values already include the minus sign
        if roundedValue > 0 {
            return "+" + percentageString
        }
        
        return percentageString
    }
}