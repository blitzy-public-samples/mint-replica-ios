// External dependencies versions:
// SwiftUI: 5.5+
// Combine: 5.5+

import SwiftUI
import Combine

// Relative imports
import "../../ViewModels/SettingsViewModel"
import "../../Models/Notification"
import "../../Mocks/MockNotificationService"

/// Human Tasks:
/// 1. Configure notification authorization request in Info.plist
/// 2. Set up notification categories in project settings
/// 3. Add appropriate usage description strings for notifications
/// 4. Verify notification handling during app state transitions

/// SwiftUI view for managing notification preferences and settings
/// Requirements addressed:
/// - Real-time notifications and alerts (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - User Preferences (Technical Specification/6.2.4 User Settings)
struct NotificationSettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SettingsViewModel(authService: MockAuthService())
    @State private var showingPermissionAlert = false
    @State private var selectedNotificationTypes = Set<NotificationType>()
    @State private var quietHoursEnabled = false
    @State private var quietHoursStart = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var quietHoursEnd = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var notificationFrequency = 0 // 0: Immediate, 1: Hourly, 2: Daily
    
    // MARK: - Private Properties
    private let notificationFrequencyOptions = ["Immediate", "Hourly", "Daily"]
    private let mockService = MockNotificationService()
    
    // MARK: - View Body
    var body: some View {
        Form {
            // Master notification toggle section
            Section(header: Text("Notifications")) {
                Toggle(isOn: $viewModel.isNotificationsEnabled) {
                    Text("Enable Notifications")
                }
                .onChange(of: viewModel.isNotificationsEnabled) { enabled in
                    if enabled {
                        requestNotificationPermission()
                    } else {
                        viewModel.toggleNotifications()
                            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                            .store(in: &viewModel.cancellables)
                    }
                }
            }
            
            // Notification types section
            if viewModel.isNotificationsEnabled {
                Section(header: Text("Notification Types")) {
                    ForEach([NotificationType.budgetAlert,
                            NotificationType.transactionAlert,
                            NotificationType.investmentUpdate]) { type in
                        Toggle(isOn: Binding(
                            get: { selectedNotificationTypes.contains(type) },
                            set: { isEnabled in
                                if isEnabled {
                                    selectedNotificationTypes.insert(type)
                                } else {
                                    selectedNotificationTypes.remove(type)
                                }
                            }
                        )) {
                            Text(notificationTypeTitle(for: type))
                        }
                    }
                }
                
                // Notification frequency section
                Section(header: Text("Update Frequency")) {
                    Picker("Frequency", selection: $notificationFrequency) {
                        ForEach(0..<notificationFrequencyOptions.count, id: \.self) { index in
                            Text(notificationFrequencyOptions[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Quiet hours section
                Section(header: Text("Quiet Hours")) {
                    Toggle(isOn: $quietHoursEnabled) {
                        Text("Enable Quiet Hours")
                    }
                    
                    if quietHoursEnabled {
                        DatePicker("Start Time",
                                 selection: $quietHoursStart,
                                 displayedComponents: .hourAndMinute)
                        
                        DatePicker("End Time",
                                 selection: $quietHoursEnd,
                                 displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
        .navigationTitle("Notification Settings")
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Notifications Disabled"),
                message: Text("Please enable notifications in Settings to receive important updates about your finances."),
                primaryButton: .default(Text("Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            loadSelectedNotificationTypes()
        }
    }
    
    // MARK: - Private Methods
    
    /// Requests system notification permissions
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    viewModel.toggleNotifications()
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &viewModel.cancellables)
                } else {
                    showingPermissionAlert = true
                    viewModel.isNotificationsEnabled = false
                }
            }
        }
    }
    
    /// Opens system settings app
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// Loads previously selected notification types
    private func loadSelectedNotificationTypes() {
        // In a real app, this would load from UserDefaults or a persistent store
        mockService.getNotifications()
            .map { notifications in
                Set(notifications.map { $0.type })
            }
            .assign(to: &$selectedNotificationTypes)
    }
    
    /// Returns a human-readable title for notification types
    private func notificationTypeTitle(for type: NotificationType) -> String {
        switch type {
        case .budgetAlert:
            return "Budget Alerts"
        case .transactionAlert:
            return "Transaction Alerts"
        case .investmentUpdate:
            return "Investment Updates"
        default:
            return ""
        }
    }
}