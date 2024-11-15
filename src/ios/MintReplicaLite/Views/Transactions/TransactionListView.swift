// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../../ViewModels/TransactionViewModel"
import "../Components/TransactionRowView"
import "../Components/LoadingView"
import "../Components/ErrorView"

// MARK: - Human Tasks
/*
 * 1. Verify VoiceOver labels and hints with accessibility team
 * 2. Test minimum touch target sizes across different device sizes
 * 3. Validate infinite scroll buffer settings with UX team
 */

/// A SwiftUI view that displays a list of financial transactions with search, filtering, and sorting capabilities
/// Requirements addressed:
/// - Transaction Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - UI Design Implementation (Technical Specification/8.1.2 Screen Layouts/Account Details)
struct TransactionListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: TransactionViewModel
    @State private var selectedSortOption: SortOption = .dateDescending
    @State private var selectedFilterOption: FilterOption = .all
    @State private var showingFilterSheet = false
    @State private var isRefreshing = false
    
    // MARK: - Initialization
    
    init(accountId: String) {
        _viewModel = StateObject(wrappedValue: TransactionViewModel(accountId: accountId))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                    
                    // Transaction List
                    if !viewModel.transactions.isEmpty {
                        transactionList
                    } else if !viewModel.isLoading {
                        emptyStateView
                    }
                }
                
                // Loading State
                if viewModel.isLoading {
                    LoadingView(
                        message: "Loading transactions...",
                        backgroundColor: .systemBackground,
                        spinnerColor: .accentColor
                    )
                }
                
                // Error State
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        title: "Unable to Load Transactions",
                        retryAction: viewModel.loadTransactions,
                        retryButtonText: "Try Again"
                    )
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortOptionsMenu
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterSheet
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search transactions", text: $viewModel.searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search transactions")
    }
    
    private var transactionList: some View {
        List {
            ForEach(viewModel.transactions) { transaction in
                TransactionRowView(transaction: transaction) {
                    // Transaction tap handler would go here
                }
                .onAppear {
                    // Implement infinite scroll loading when reaching end of list
                    if transaction == viewModel.transactions.last {
                        viewModel.loadTransactions()
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            isRefreshing = true
            await viewModel.loadTransactions()
            isRefreshing = false
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No transactions found")
                .font(.headline)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No transactions found. Try adjusting your search or filters.")
    }
    
    private var sortOptionsMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    selectedSortOption = option
                    // Implement sort logic here
                } label: {
                    Label(
                        option.displayText,
                        systemImage: selectedSortOption == option ? "checkmark" : ""
                    )
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
                .labelStyle(.iconOnly)
        }
        .accessibilityLabel("Sort transactions")
        .accessibilityHint("Double tap to show sorting options")
    }
    
    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter transactions")
        .accessibilityHint("Double tap to show filter options")
    }
    
    private var filterSheet: some View {
        NavigationView {
            List(FilterOption.allCases, id: \.self) { option in
                Button {
                    selectedFilterOption = option
                    showingFilterSheet = false
                    // Implement filter logic here
                } label: {
                    HStack {
                        Text(option.displayText)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedFilterOption == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilterSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Enums

/// Available transaction sort options
enum SortOption: CaseIterable {
    case dateDescending
    case dateAscending
    case amountDescending
    case amountAscending
    
    var displayText: String {
        switch self {
        case .dateDescending:
            return "Newest First"
        case .dateAscending:
            return "Oldest First"
        case .amountDescending:
            return "Highest Amount"
        case .amountAscending:
            return "Lowest Amount"
        }
    }
}

/// Available transaction filter options
enum FilterOption: CaseIterable {
    case all
    case pending
    case completed
    case income
    case expense
    
    var displayText: String {
        switch self {
        case .all:
            return "All Transactions"
        case .pending:
            return "Pending"
        case .completed:
            return "Completed"
        case .income:
            return "Income"
        case .expense:
            return "Expenses"
        }
    }
}

#if DEBUG
// MARK: - Preview Provider
struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView(accountId: "preview-account-id")
    }
}
#endif