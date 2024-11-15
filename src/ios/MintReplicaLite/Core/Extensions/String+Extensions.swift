// Foundation v5.5+
import Foundation
import NumberFormatter

// MARK: - Human Tasks
// 1. Verify string validation behavior with international characters and locales
// 2. Add unit tests for email validation edge cases
// 3. Test truncation with various Unicode character sets

/// String extensions providing financial formatting and validation utilities
extension String {
    
    // MARK: - Financial Formatting
    
    /// Converts string to properly formatted currency string using system locale
    /// Addresses requirement: Financial Data Display - Technical Specification/8.1.2 Main Dashboard
    func toCurrencyString() -> String {
        guard let number = Double(self.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)) else {
            return ""
        }
        return NumberFormatterUtility.shared.formatCurrency(number)
    }
    
    /// Converts string to percentage format with specified decimal places
    /// Addresses requirement: Investment Returns Display - Technical Specification/8.1.5 Investment Dashboard
    func toPercentageString(decimalPlaces: Int = 1) -> String {
        guard let number = Double(self.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)) else {
            return ""
        }
        return NumberFormatterUtility.shared.formatPercentage(number)
    }
    
    // MARK: - Validation
    
    /// Validates if string represents a valid financial amount
    func isValidAmount() -> Bool {
        // Remove currency symbols, spaces, and grouping separators
        let cleanString = self.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
        
        // Financial amount regex pattern
        let pattern = "^-?\\d*\\.?\\d{0,2}$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let range = NSRange(cleanString.startIndex..., in: cleanString)
        let matches = regex.matches(in: cleanString, range: range)
        
        // Validate amount and ensure it can be converted to Double
        return !matches.isEmpty && Double(cleanString) != nil
    }
    
    /// Validates if string represents a valid email address using RFC 5322 standard
    func isValidEmail() -> Bool {
        // RFC 5322 compliant email regex pattern
        let pattern = "^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$"
        
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return emailPredicate.evaluate(with: self.lowercased())
    }
    
    // MARK: - String Manipulation
    
    /// Truncates string to specified length while maintaining word boundaries
    func truncate(length: Int) -> String {
        guard self.count > length else {
            return self
        }
        
        let truncatedString = self.prefix(length)
        guard let lastSpace = truncatedString.lastIndex(of: " ") else {
            return String(truncatedString) + "..."
        }
        
        return String(self[..<lastSpace]) + "..."
    }
}