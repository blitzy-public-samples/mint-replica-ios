// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../../Models/Account"
import "../../ViewModels/AccountViewModel"
import "../Components/AccountCardView"
import "../Components/LoadingView"

// MARK: - Human Tasks
// 1. Verify VoiceOver navigation flow with accessibility team
// 2. Test pull-to-refresh gesture with various network conditions
// 3. Validate minimum touch target sizes across all device sizes

/// Main view for displaying and managing financial accounts
/// Addresses requirements:
/// - Financial Account Integration (Technical Specification/1.2 Scope/Core Features)
/// - Account List UI (Technical Specification/8.1.2 Main Dashboard/Accounts Overview)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct AccountsListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: AccountViewModel
    @State private var selectedAccountId: String?
    @State private var showingLinkAccount: Bool = false
    
    // MARK: - Initialization
    
    init() {
        let accountService = MockAccountService()
        _viewModel = StateObject(wrappedValue: AccountViewModel(accountService: accountService))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.accounts) { account in
                            AccountCardView(
                                account: account,
                                isSelected: account.id == selectedAccountId,
                                onTap: { handleAccountSelection(account) }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await refreshAccounts()
                }
                .overlay(Group {
                    if viewModel.accounts.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No accounts found")
                                .font(.headline)
                            
                            Button("Add Account") {
                                showingLinkAccount = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("No accounts found. Tap to add an account.")
                    }
                })
                
                if viewModel.isLoading {
                    LoadingView(
                        message: "Loading accounts...",
                        backgroundColor: Color(.systemBackground),
                        spinnerColor: .accentColor
                    )
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingLinkAccount = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .accessibilityLabel("Add account")
                    }
                    .frame(width: 44, height: 44) // Minimum touch target size
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingLinkAccount) {
                // Note: Link account view to be implemented separately
                Text("Link Account View")
                    .navigationTitle("Link Account")
            }
        }
        .task {
            await refreshAccounts()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Accounts List")
    }
    
    // MARK: - Private Methods
    
    /// Refreshes the accounts list
    private func refreshAccounts() async {
        await viewModel.fetchAccounts()
    }
    
    /// Handles the selection of an account
    /// - Parameter account: The selected account
    private func handleAccountSelection(_ account: Account) {
        selectedAccountId = account.id
        // Note: Navigation to account details will be handled by parent view
    }
}

#if DEBUG
struct AccountsListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsListView()
    }
}
#endif