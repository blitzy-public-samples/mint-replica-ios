// Foundation v5.5+
import Foundation
// SwiftUI v5.5+
import SwiftUI

// MARK: - Layout Constants
/// Defines standard layout measurements compliant with iOS design guidelines
/// Addresses requirement: Mobile Responsive Design - Technical Specification/8.1.7 Mobile Responsive Considerations
/// Addresses requirement: Accessibility Support - Technical Specification/8.1.8 Accessibility Features
struct Layout {
    /// Minimum touch target size compliant with iOS accessibility guidelines (44x44 points)
    static let minimumTouchTarget: CGFloat = 44.0
    
    /// Standard padding used throughout the app for consistent spacing
    static let standardPadding: CGFloat = 16.0
    
    /// Standard corner radius for cards and buttons
    static let cornerRadius: CGFloat = 12.0
    
    /// Standard icon size used throughout the app
    static let iconSize: CGFloat = 24.0
    
    /// Standard height for list items
    static let listItemHeight: CGFloat = 60.0
    
    /// Standard padding for card views
    static let cardPadding: CGFloat = 20.0
}

// MARK: - Animation Constants
/// Defines standard animation durations for consistent UI interactions
/// Addresses requirement: Design System Implementation - Technical Specification/8.1.1 Design System Key
struct Animation {
    /// Standard animation duration for most UI transitions
    static let standard: Double = 0.3
    
    /// Quick animation duration for subtle UI feedback
    static let quick: Double = 0.15
    
    /// Animation duration for card transitions
    static let cardTransition: Double = 0.4
}

// MARK: - Date Format Constants
/// Defines standard date format strings for consistent date display
/// Addresses requirement: iOS Native Development - Technical Specification/1.2 Scope/Technical Implementation
struct DateFormat {
    /// Format used for displaying dates in the UI
    static let displayFormat: String = "MMM dd, yyyy"
    
    /// Format used for API requests and responses
    static let apiFormat: String = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    
    /// Format used specifically for transaction dates
    static let transactionFormat: String = "MMM dd"
}

// MARK: - API Constants
/// Defines API-related constants for network requests
struct API {
    /// Base URL for API endpoints
    static let baseURL: String = "https://api.mintreplicalite.com"
    
    /// API version string
    static let version: String = "v1"
    
    /// Network request timeout interval in seconds
    static let timeout: TimeInterval = 30.0
}

// MARK: - UserDefaults Keys
/// Defines UserDefaults storage keys for app preferences
struct UserDefaultsKeys {
    /// Key for storing user authentication token
    static let userToken: String = "com.mintreplicalite.userToken"
    
    /// Key for storing last sync timestamp
    static let lastSync: String = "com.mintreplicalite.lastSync"
    
    /// Key for storing user's selected theme
    static let selectedTheme: String = "com.mintreplicalite.selectedTheme"
}

// MARK: - Notification Constants
/// Defines notification-related constants for alerts and notifications
struct NotificationConstants {
    /// Threshold percentage for budget alerts
    static let budgetAlertThreshold: Double = 0.85
    
    /// Minimum amount for transaction alerts
    static let transactionAlertMinimum: Double = 100.0
    
    /// Duration for displaying in-app alerts
    static let alertDisplayDuration: TimeInterval = 3.0
}

// MARK: - Validation Constants
/// Defines validation-related constants for form validation
struct ValidationConstants {
    /// Minimum required password length
    static let minimumPasswordLength: Int = 8
    
    /// Maximum allowed goal amount
    static let maximumGoalAmount: Double = 1_000_000.0
    
    /// Maximum number of budget categories allowed
    static let maximumBudgetCategories: Int = 20
}

// MARK: - Accessibility Identifiers
/// Defines accessibility identifiers for UI testing
/// Addresses requirement: Accessibility Support - Technical Specification/8.1.8 Accessibility Features
struct AccessibilityIdentifiers {
    /// Identifier for the dashboard view
    static let dashboardView: String = "DashboardView"
    
    /// Identifier for the transaction list
    static let transactionList: String = "TransactionList"
    
    /// Identifier for the budget progress view
    static let budgetProgress: String = "BudgetProgress"
}