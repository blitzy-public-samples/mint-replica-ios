// Foundation v5.5+
import Foundation

// Relative imports for date formatting utilities
import "../Utilities/DateFormatter"
import "../Utilities/Constants"

// MARK: - Human Tasks
/*
 * 1. Verify timezone handling across different regions during testing
 * 2. Add unit tests for edge cases like daylight savings transitions
 * 3. Validate date calculations around month/year boundaries
 * 4. Test locale-specific week start day calculations
 */

// MARK: - Date Extension
/// Extension providing financial app-specific date manipulation functionality
/// with proper timezone and locale handling for the MintReplicaLite iOS application
extension Date {
    
    // MARK: - Month Operations
    
    /// Returns the first day of the month containing this date, preserving timezone
    /// Addresses requirement: Budget Period Management (Technical Specification/8.1.4)
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: DateComponents(year: components.year,
                                                month: components.month,
                                                day: 1,
                                                hour: 0,
                                                minute: 0,
                                                second: 0))!
    }
    
    /// Returns the last day of the month containing this date, preserving timezone
    /// Addresses requirement: Budget Period Management (Technical Specification/8.1.4)
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return calendar.date(byAdding: components,
                           to: self.startOfMonth())!
    }
    
    // MARK: - Week Operations
    
    /// Returns the first day of the week containing this date, using user's locale settings
    /// Addresses requirement: Budget Period Management (Technical Specification/8.1.4)
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: DateComponents(yearForWeekOfYear: components.yearForWeekOfYear,
                                                weekOfYear: components.weekOfYear,
                                                weekday: calendar.firstWeekday,
                                                hour: 0,
                                                minute: 0,
                                                second: 0))!
    }
    
    // MARK: - Date Comparison
    
    /// Checks if this date is in the same month as another date, timezone-aware
    /// Addresses requirement: Transaction Date Handling (Technical Specification/6.2.2)
    func isInSameMonth(as other: Date) -> Bool {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.year, .month], from: self)
        let otherComponents = calendar.dateComponents([.year, .month], from: other)
        return selfComponents.year == otherComponents.year &&
               selfComponents.month == otherComponents.month
    }
    
    /// Calculates number of months between this date and another date, handling timezone differences
    /// Addresses requirement: Investment Performance Tracking (Technical Specification/8.1.5)
    func monthsBetween(_ other: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month],
                                              from: self,
                                              to: other)
        return components.month ?? 0
    }
    
    // MARK: - Date Manipulation
    
    /// Returns a new date by adding specified number of months, preserving timezone
    /// Addresses requirement: Investment Performance Tracking (Technical Specification/8.1.5)
    func addingMonths(_ months: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = months
        return calendar.date(byAdding: components, to: self)!
    }
    
    // MARK: - Formatting
    
    /// Returns date formatted using standard display format with proper localization
    /// Addresses requirement: Transaction Date Handling (Technical Specification/6.2.2)
    func formattedForDisplay() -> String {
        return DateFormatterUtility.shared.formatForDisplay(self)
    }
}