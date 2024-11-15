// Foundation v5.5+
import Foundation
// Combine v5.5+
import Combine

// MARK: - Human Tasks
/*
 * 1. Add unit tests for mock notification generation and event simulation
 * 2. Verify WebSocket event simulation matches production behavior
 * 3. Configure notification permissions in test environment
 */

// MARK: - Relative Imports
import "../Models/Notification"
import "../Core/Utilities/Constants"

/// Mock service implementation for simulating notification functionality
/// Addresses requirement: Real-time notifications and alerts - Technical Specification/1.2 Scope/Core Features
class MockNotificationService {
    // MARK: - Properties
    private let notificationsSubject = CurrentValueSubject<[Notification], Never>([])
    private var mockNotifications: [Notification] = []
    private let newNotificationSubject = PassthroughSubject<Notification, Never>()
    
    // MARK: - Initialization
    init() {
        setupMockNotifications()
    }
    
    // MARK: - Private Methods
    private func setupMockNotifications() {
        let now = Date()
        
        // Budget alert notification
        let budgetNotification = Notification(
            id: UUID().uuidString,
            type: .budgetAlert,
            title: "Budget Alert",
            message: "You've reached 85% of your Dining budget",
            timestamp: now.addingTimeInterval(-3600),
            priority: .high,
            data: NotificationData(budgetId: "budget123", percentage: NotificationConstants.budgetAlertThreshold)
        )
        
        // Transaction alert notification
        let transactionNotification = Notification(
            id: UUID().uuidString,
            type: .transactionAlert,
            title: "Large Transaction",
            message: "Transaction of $150.00 detected",
            timestamp: now.addingTimeInterval(-7200),
            priority: .medium,
            data: NotificationData(transactionId: "trans456", amount: NotificationConstants.transactionAlertMinimum)
        )
        
        // Investment update notification
        let investmentNotification = Notification(
            id: UUID().uuidString,
            type: .investmentUpdate,
            title: "Investment Update",
            message: "Your portfolio has increased by 2.5%",
            timestamp: now.addingTimeInterval(-14400),
            priority: .low,
            data: NotificationData(accountId: "inv789", percentage: 2.5)
        )
        
        mockNotifications = [budgetNotification, transactionNotification, investmentNotification]
        notificationsSubject.send(mockNotifications)
    }
    
    // MARK: - Public Methods
    /// Retrieves all notifications as a publisher
    /// Addresses requirement: WebSocket Events - Technical Specification/8.3.3 WebSocket Events
    func getNotifications() -> AnyPublisher<[Notification], Never> {
        return notificationsSubject.eraseToAnyPublisher()
    }
    
    /// Marks a notification as read by ID
    func markAsRead(notificationId: String) {
        if let index = mockNotifications.firstIndex(where: { $0.id == notificationId }) {
            mockNotifications[index].markAsRead()
            notificationsSubject.send(mockNotifications)
        }
    }
    
    /// Simulates receiving a new notification of specified type
    /// Addresses requirement: Budget Alert Notifications - Technical Specification/6.2.2 Transaction Processing Flow
    func simulateNewNotification(type: NotificationType) {
        let notification: Notification
        let now = Date()
        
        switch type {
        case .budgetAlert:
            notification = Notification(
                id: UUID().uuidString,
                type: type,
                title: "Budget Alert",
                message: "Budget threshold exceeded",
                timestamp: now,
                priority: .high,
                data: NotificationData(budgetId: "budget\(UUID().uuidString)", 
                                    percentage: NotificationConstants.budgetAlertThreshold)
            )
            
        case .transactionAlert:
            notification = Notification(
                id: UUID().uuidString,
                type: type,
                title: "Transaction Alert",
                message: "Large transaction detected",
                timestamp: now,
                priority: .medium,
                data: NotificationData(transactionId: "trans\(UUID().uuidString)", 
                                    amount: NotificationConstants.transactionAlertMinimum)
            )
            
        case .investmentUpdate:
            notification = Notification(
                id: UUID().uuidString,
                type: type,
                title: "Investment Update",
                message: "Portfolio change detected",
                timestamp: now,
                priority: .low,
                data: NotificationData(accountId: "inv\(UUID().uuidString)", 
                                    percentage: 1.5)
            )
            
        case .goalProgress:
            notification = Notification(
                id: UUID().uuidString,
                type: type,
                title: "Goal Progress",
                message: "You're closer to your savings goal",
                timestamp: now,
                priority: .medium,
                data: NotificationData(goalId: "goal\(UUID().uuidString)", 
                                    percentage: 75.0)
            )
            
        case .accountSync:
            notification = Notification(
                id: UUID().uuidString,
                type: type,
                title: "Account Sync",
                message: "Account sync completed",
                timestamp: now,
                priority: .low,
                data: NotificationData(accountId: "acc\(UUID().uuidString)")
            )
            
        case .securityAlert:
            notification = Notification(
                id: UUID().uuidString,
                type: type,
                title: "Security Alert",
                message: "Unusual account activity detected",
                timestamp: now,
                priority: .high,
                data: NotificationData(accountId: "acc\(UUID().uuidString)")
            )
        }
        
        mockNotifications.insert(notification, at: 0)
        newNotificationSubject.send(notification)
        notificationsSubject.send(mockNotifications)
    }
    
    /// Provides a publisher for new notifications
    /// Addresses requirement: WebSocket Events - Technical Specification/8.3.3 WebSocket Events
    func observeNewNotifications() -> AnyPublisher<Notification, Never> {
        return newNotificationSubject.eraseToAnyPublisher()
    }
}