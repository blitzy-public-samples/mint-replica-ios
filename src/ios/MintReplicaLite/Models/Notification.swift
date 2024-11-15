// Foundation v5.5+
import Foundation

// MARK: - Human Tasks
/*
 * 1. Verify notification handling during app background/foreground transitions
 * 2. Add unit tests for notification data parsing from WebSocket events
 * 3. Configure notification categories in project settings for iOS
 * 4. Set up notification authorization request in AppDelegate
 */

// MARK: - Relative Imports
import "../Core/Utilities/Constants"
import "../Core/Extensions/Date+Extensions"

// MARK: - Notification Type
/// Enumeration of possible notification types aligned with WebSocket events
/// Addresses requirement: WebSocket Events - Technical Specification/8.3.3 WebSocket Events
@frozen
enum NotificationType {
    case budgetAlert
    case transactionAlert
    case investmentUpdate
    case goalProgress
    case accountSync
    case securityAlert
}

// MARK: - Notification Priority
/// Enumeration of notification priority levels for UI display
@frozen
enum NotificationPriority {
    case high
    case medium
    case low
}

// MARK: - Notification Data
/// Structure containing type-specific notification data for different WebSocket events
/// Addresses requirement: WebSocket Events - Technical Specification/8.3.3 WebSocket Events
struct NotificationData {
    let budgetId: String?
    let amount: Double?
    let accountId: String?
    let transactionId: String?
    let goalId: String?
    let percentage: Double?
    
    init(budgetId: String? = nil,
         amount: Double? = nil,
         accountId: String? = nil,
         transactionId: String? = nil,
         goalId: String? = nil,
         percentage: Double? = nil) {
        self.budgetId = budgetId
        self.amount = amount
        self.accountId = accountId
        self.transactionId = transactionId
        self.goalId = goalId
        self.percentage = percentage
    }
}

// MARK: - Notification Model
/// Model representing a financial notification in the MintReplicaLite app
/// Addresses requirement: Real-time notifications and alerts - Technical Specification/1.2 Scope/Core Features
@frozen
class Notification {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let priority: NotificationPriority
    let data: NotificationData?
    private(set) var isRead: Bool
    
    /// Creates a new notification instance with required fields and optional data
    /// Addresses requirement: Budget Alert Notifications - Technical Specification/6.2.2 Transaction Processing Flow
    init(id: String,
         type: NotificationType,
         title: String,
         message: String,
         timestamp: Date,
         priority: NotificationPriority,
         data: NotificationData? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.priority = priority
        self.data = data
        self.isRead = false
    }
    
    /// Marks the notification as read
    func markAsRead() {
        isRead = true
    }
    
    /// Returns the notification timestamp formatted for display using proper locale
    func formattedTimestamp() -> String {
        return timestamp.formattedForDisplay()
    }
}