// Foundation v5.5+
import Foundation

/// Relative import for date format constants
import "../Constants"

// MARK: - Human Tasks
/*
 * 1. Ensure device timezone settings are properly configured for accurate date handling
 * 2. Verify locale settings on test devices to confirm proper date localization
 * 3. Add unit tests to verify date formatting across different locales and timezones
 */

/// A thread-safe singleton class providing centralized date formatting functionality
/// for consistent date handling across the MintReplicaLite iOS application.
///
/// Addresses requirements:
/// - Transaction Date Handling (Technical Specification/6.2.2)
/// - Budget Period Management (Technical Specification/8.1.4)
/// - Investment Performance Tracking (Technical Specification/8.1.5)
final class DateFormatterUtility {
    
    // MARK: - Singleton Instance
    
    /// Shared singleton instance for centralized date formatting
    static let shared = DateFormatterUtility()
    
    // MARK: - Properties
    
    /// DateFormatter instance configured for display formatting with localization
    private let displayFormatter: DateFormatter
    
    /// DateFormatter instance configured for API communication
    private let apiFormatter: DateFormatter
    
    /// Serial queue for thread-safe date formatting operations
    private let formatterQueue = DispatchQueue(label: "com.mintreplicalite.dateformatter")
    
    // MARK: - Initialization
    
    private init() {
        // Initialize display formatter with localized settings
        displayFormatter = DateFormatter()
        displayFormatter.dateFormat = DateFormat.displayFormat
        displayFormatter.locale = Locale.current
        displayFormatter.timeZone = TimeZone.current
        displayFormatter.isLenient = false
        
        // Initialize API formatter with strict ISO8601 settings
        apiFormatter = DateFormatter()
        apiFormatter.dateFormat = DateFormat.apiFormat
        apiFormatter.locale = Locale(identifier: "en_US_POSIX") // POSIX locale for API consistency
        apiFormatter.timeZone = TimeZone(secondsFromGMT: 0)! // UTC for API communication
        apiFormatter.isLenient = false
    }
    
    // MARK: - Public Methods
    
    /// Formats a date using the standard display format with proper localization
    /// - Parameter date: The date to format
    /// - Returns: A localized string representation of the date
    func formatForDisplay(_ date: Date) -> String {
        return formatterQueue.sync {
            return displayFormatter.string(from: date)
        }
    }
    
    /// Formats a date using the API format for network communication
    /// - Parameter date: The date to format
    /// - Returns: A string representation of the date in API format
    func formatForAPI(_ date: Date) -> String {
        return formatterQueue.sync {
            return apiFormatter.string(from: date)
        }
    }
    
    /// Parses a string in API format to a Date object
    /// - Parameter dateString: The date string to parse
    /// - Returns: An optional Date object, nil if parsing fails
    func date(from dateString: String) -> Date? {
        return formatterQueue.sync {
            return apiFormatter.date(from: dateString)
        }
    }
}