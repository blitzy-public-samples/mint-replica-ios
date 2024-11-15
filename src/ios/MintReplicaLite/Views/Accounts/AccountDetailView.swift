// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../../ViewModels/AccountViewModel"
import "../../Models/Account"
import "../Components/TransactionRowView"

// MARK: - Human Tasks
// 1. Test VoiceOver flows with screen reader
// 2. Verify pull-to-refresh behavior across iOS versions
// 3. Validate search performance with large transaction lists
// 4. Review filter sheet animations with design team

/// A SwiftUI view that displays detailed information about a specific financial account
/// Requirements addressed:
/// - Account Detail View (Technical Specification/8.1.2 Screen Layouts/Account Details)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct AccountDetailView: View {
    // MARK: - Properties
    
    let account: Account
    @StateObject private var viewModel: AccountViewModel
    @State private var searchText = ""
    @State private var selectedFilter: String?
    @State private var showingFilterSheet = false
    @State private var isRefreshing = false
    
    // MARK: - Constants
    
    private enum Constants {
        static let minTouchTarget: CGFloat = 44
        static let standardPadding: CGFloat = 16
        static let headerSpacing: CGFloat = 8
        static let filterButtonSize: CGFloat = 44
    }
    
    // MARK: - Initialization
    
    init(account: Account) {
        self.account = account
        _viewModel = StateObject(wrappedValue: AccountViewModel(accountService: MockAccountService()))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: Constants.standardPadding) {
                    // Account Balance Header
                    VStack(alignment: .leading, spacing: Constants.headerSpacing) {
                        Text(account.formattedBalance())
                            .font(.title)
                            .fontWeight(.semibold)
                            .accessibilityLabel("Account balance \(account.formattedBalance())")
                        
                        Text("Last synced: \(account.formattedLastSynced())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Last synced \(account.formattedLastSynced())")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Search and Filter Section
                    HStack(spacing: Constants.standardPadding) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search transactions", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.default)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .frame(width: Constants.filterButtonSize, height: Constants.filterButtonSize)
                        }
                        .accessibilityLabel("Filter transactions")
                        .sheet(isPresented: $showingFilterSheet) {
                            FilterSheetView(selectedFilter: $selectedFilter)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Transaction List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredTransactions) { transaction in
                                TransactionRowView(transaction: transaction)
                                    .padding(.horizontal)
                                Divider()
                            }
                        }
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
                
                // Loading Indicator
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationTitle("Account Details")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Refreshes account data when pulled to refresh
    private func refreshData() async {
        isRefreshing = true
        await viewModel.refreshAccount(accountId: account.id)
        isRefreshing = false
    }
    
    /// Returns filtered transactions based on search text and category filter
    private var filteredTransactions: [Transaction] {
        // Note: This is a mock implementation since Transaction model is not provided
        // In a real implementation, this would filter the account's transactions
        return []
    }
}

// MARK: - Filter Sheet View

private struct FilterSheetView: View {
    @Binding var selectedFilter: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Button("All Transactions") {
                    selectedFilter = nil
                    dismiss()
                }
                
                // Note: In a real implementation, this would show category filters
                // based on available transaction categories
            }
            .navigationTitle("Filter Transactions")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - Preview Provider

struct AccountDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAccount = Account(
            id: "mock-id",
            institutionId: "mock-institution",
            accountType: .checking,
            balance: 1000.0,
            currency: "USD",
            lastSynced: Date(),
            isActive: true
        )
        
        AccountDetailView(account: mockAccount)
    }
}