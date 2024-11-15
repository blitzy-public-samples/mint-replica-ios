// External dependencies versions:
// SwiftUI: 5.5+
// Combine: 5.5+

import SwiftUI
import Combine

// Relative imports
import "../ViewModels/SettingsViewModel"
import "../Models/User"
import "../Core/Extensions/View+Extensions"

/// Human Tasks:
/// 1. Configure image picker for profile photo functionality
/// 2. Set up proper keyboard handling for text fields
/// 3. Configure proper accessibility labels for VoiceOver support

/// SwiftUI view for managing user profile and settings
/// Requirements addressed:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - User Profile Management (Technical Specification/6.1.1 Core Application Components)
struct ProfileView: View {
    // MARK: - Properties
    @StateObject private var viewModel: SettingsViewModel
    @State private var isEditMode = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var showingLogoutAlert = false
    @State private var showingErrorAlert = false
    
    // MARK: - Currency Options
    private let currencyOptions = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
    
    // MARK: - Initialization
    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                profileHeader
                
                // Profile Information
                profileInformation
                
                // Settings Toggles
                settingsToggles
                
                // Currency Selection
                currencySelection
                
                // Logout Button
                logoutButton
            }
            .standardPadding()
        }
        .navigationTitle("Profile")
        .loadingOverlay(viewModel.isLoading)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack {
            if let imageUrl = viewModel.currentUser?.profileImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            Button(isEditMode ? "Save" : "Edit") {
                if isEditMode {
                    saveProfile()
                } else {
                    enterEditMode()
                }
            }
            .accessibleTapTarget()
        }
        .cardStyle()
    }
    
    // MARK: - Profile Information
    private var profileInformation: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditMode {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name: \(viewModel.currentUser?.fullName ?? "")")
                        .font(.body)
                    
                    Text("Email: \(viewModel.currentUser?.email ?? "")")
                        .font(.body)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Settings Toggles
    private var settingsToggles: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Biometric Authentication", isOn: Binding(
                get: { viewModel.isBiometricEnabled },
                set: { _ in
                    toggleBiometric()
                }
            ))
            
            Toggle("Enable Notifications", isOn: Binding(
                get: { viewModel.isNotificationsEnabled },
                set: { _ in
                    toggleNotifications()
                }
            ))
        }
        .cardStyle()
    }
    
    // MARK: - Currency Selection
    private var currencySelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preferred Currency")
                .font(.headline)
            
            Picker("Currency", selection: Binding(
                get: { viewModel.selectedCurrency },
                set: { newValue in
                    updateCurrency(newValue)
                }
            )) {
                ForEach(currencyOptions, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .cardStyle()
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: {
            showingLogoutAlert = true
        }) {
            Text("Logout")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        }
        .accessibleTapTarget()
    }
    
    // MARK: - Helper Methods
    private func enterEditMode() {
        firstName = viewModel.currentUser?.firstName ?? ""
        lastName = viewModel.currentUser?.lastName ?? ""
        email = viewModel.currentUser?.email ?? ""
        isEditMode = true
    }
    
    private func saveProfile() {
        viewModel.updateProfile(firstName: firstName, lastName: lastName, email: email)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure = completion {
                    showingErrorAlert = true
                }
            } receiveValue: { success in
                if success {
                    isEditMode = false
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    private func toggleBiometric() {
        viewModel.toggleBiometricAuth()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure = completion {
                    showingErrorAlert = true
                }
            } receiveValue: { _ in }
            .store(in: &viewModel.cancellables)
    }
    
    private func toggleNotifications() {
        viewModel.toggleNotifications()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure = completion {
                    showingErrorAlert = true
                }
            } receiveValue: { _ in }
            .store(in: &viewModel.cancellables)
    }
    
    private func updateCurrency(_ currency: String) {
        viewModel.updateCurrency(currency)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure = completion {
                    showingErrorAlert = true
                }
            } receiveValue: { _ in }
            .store(in: &viewModel.cancellables)
    }
    
    private func handleLogout() {
        viewModel.logout()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure = completion {
                    showingErrorAlert = true
                }
            } receiveValue: { _ in }
            .store(in: &viewModel.cancellables)
    }
}