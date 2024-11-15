// External dependencies versions:
// SwiftUI: 5.5+
// Combine: 5.5+

import SwiftUI
import Combine

// Relative imports
import "../../ViewModels/SettingsViewModel"
import "../../Core/Extensions/View+Extensions"
import "../Components/LoadingView"

/// Human Tasks:
/// 1. Verify biometric authentication permissions are configured in Info.plist
/// 2. Ensure notification permissions are properly configured
/// 3. Test all accessibility labels with VoiceOver
/// 4. Verify minimum touch targets on physical devices

/// Main settings view that provides user preferences management interface
/// Requirements addressed:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SettingsViewModel(authService: MockAuthService())
    @State private var showingLogoutAlert = false
    @State private var showingCurrencyPicker = false
    @State private var showingErrorAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    profileSection()
                    securitySection()
                    notificationsSection()
                    currencySection()
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("Logout")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibleTapTarget()
                }
                .standardPadding()
            }
            .navigationTitle("Settings")
            .loadingOverlay(viewModel.isLoading)
            .alert("Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.logout().value
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Section Views
    private func profileSection() -> some View {
        VStack(spacing: 12) {
            if let user = viewModel.currentUser {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
                
                Text("\(user.firstName) \(user.lastName)")
                    .font(.title2)
                    .bold()
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Edit Profile") {
                    Task {
                        do {
                            try await viewModel.updateProfile(
                                firstName: user.firstName,
                                lastName: user.lastName,
                                email: user.email
                            ).value
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                    }
                }
                .buttonStyle(.bordered)
                .accessibleTapTarget()
            }
        }
        .cardStyle()
    }
    
    private func securitySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(.headline)
            
            Toggle(isOn: .init(
                get: { viewModel.isBiometricEnabled },
                set: { isEnabled in
                    Task {
                        do {
                            try await viewModel.toggleBiometricAuth().value
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                    }
                }
            )) {
                Text("Biometric Authentication")
            }
            .accessibleTapTarget()
        }
        .cardStyle()
    }
    
    private func notificationsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)
            
            Toggle(isOn: .init(
                get: { viewModel.isNotificationsEnabled },
                set: { isEnabled in
                    Task {
                        do {
                            try await viewModel.toggleNotifications().value
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                    }
                }
            )) {
                Text("Push Notifications")
            }
            .accessibleTapTarget()
        }
        .cardStyle()
    }
    
    private func currencySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currency")
                .font(.headline)
            
            Button(action: {
                showingCurrencyPicker = true
            }) {
                HStack {
                    Text("Preferred Currency")
                    Spacer()
                    Text(viewModel.selectedCurrency)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .accessibleTapTarget()
        }
        .cardStyle()
        .sheet(isPresented: $showingCurrencyPicker) {
            NavigationView {
                List(["USD", "EUR", "GBP", "JPY"], id: \.self) { currency in
                    Button(action: {
                        Task {
                            do {
                                try await viewModel.updateCurrency(currency).value
                                showingCurrencyPicker = false
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                                showingErrorAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Text(currency)
                            Spacer()
                            if currency == viewModel.selectedCurrency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .navigationTitle("Select Currency")
                .navigationBarItems(trailing: Button("Done") {
                    showingCurrencyPicker = false
                })
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif