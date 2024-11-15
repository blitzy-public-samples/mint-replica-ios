// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../ViewModels/DashboardViewModel"
import "../Components/AccountCardView"
import "../Components/BudgetProgressCard"
import "../Components/TransactionRowView"

// MARK: - Human Tasks
// 1. Verify VoiceOver labels with accessibility team
// 2. Test pull-to-refresh gesture sensitivity
// 3. Validate color contrast ratios in dark mode
// 4. Review animation performance on older devices

/// Main dashboard view displaying financial overview with account cards, budget progress, and recent transactions
/// Addresses requirements:
/// - Core Features - Dashboard (Technical Specification/8.1.1 Mobile Navigation Structure/Dashboard)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct DashboardView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedAccountId: String?
    @State private var showingAccountDetail: Bool = false
    @State private var showingBudgetDetail: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            RefreshControl(coordinateSpace: .named("pullToRefresh")) {
                Task {
                    await viewModel.refreshData()
                }
            }
            
            VStack(spacing: 24) {
                // Total Balance Section
                totalBalanceSection
                
                // Accounts Section
                accountsSection
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Accounts overview")
                
                // Budget Section
                budgetSection
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Budget overview")
                
                // Recent Transactions Section
                recentTransactionsSection
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Recent transactions")
            }
            .padding()
        }
        .coordinateSpace(name: "pullToRefresh")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
                    .accessibilityLabel("Loading dashboard data")
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .navigationDestination(isPresented: $showingAccountDetail) {
            if let selectedId = selectedAccountId {
                // Navigation handled by parent view
                EmptyView()
                    .navigationBarBackButtonHidden(false)
                    .accessibilityLabel("Account details for selected account")
            }
        }
        .navigationDestination(isPresented: $showingBudgetDetail) {
            // Navigation handled by parent view
            EmptyView()
                .navigationBarBackButtonHidden(false)
                .accessibilityLabel("Budget details")
        }
    }
    
    // MARK: - Section Views
    
    private var totalBalanceSection: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(String(format: "$%.2f", viewModel.totalBalance))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total balance \(String(format: "%.2f dollars", viewModel.totalBalance))")
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Accounts")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    Task {
                        await viewModel.refreshData()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.large)
                }
                .accessibilityLabel("Refresh accounts")
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.accounts, id: \.id) { account in
                        AccountCardView(
                            account: account,
                            isSelected: account.id == selectedAccountId
                        ) { selectedAccount in
                            selectedAccountId = selectedAccount.id
                            showingAccountDetail = true
                        }
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal, 1) // Prevent clipping of shadows
            }
        }
    }
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Budget Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingBudgetDetail = true
                } label: {
                    Text("See All")
                        .foregroundColor(.accentColor)
                }
                .accessibilityHint("View all budget categories")
            }
            
            VStack(spacing: 12) {
                // Note: In a real implementation, budgets would be provided by the ViewModel
                // Using a mock budget here for demonstration
                BudgetProgressCard(
                    budget: try! Budget(
                        id: "mock",
                        name: "Monthly Budget",
                        amount: 1000.0,
                        category: "Groceries",
                        period: .monthly,
                        startDate: Date(),
                        endDate: Date().addingTimeInterval(2592000),
                        spent: 750.0
                    ),
                    isCompact: true
                )
            }
        }
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                ForEach(viewModel.recentTransactions.prefix(5), id: \.id) { transaction in
                    TransactionRowView(transaction: transaction) {
                        // Transaction tap handling would be implemented here
                    }
                    
                    if transaction.id != viewModel.recentTransactions.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - RefreshControl

private struct RefreshControl: View {
    let coordinateSpace: CoordinateSpace
    let onRefresh: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geometry in
            if offset > 50 && !isRefreshing {
                Spacer()
                    .onAppear {
                        isRefreshing = true
                        onRefresh()
                        
                        // Reset after refresh
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isRefreshing = false
                        }
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .offset(y: geometry.frame(in: coordinateSpace).minY > 0 ? geometry.frame(in: coordinateSpace).minY : 0)
                }
                Spacer()
            }
            .preference(
                key: OffsetPreferenceKey.self,
                value: geometry.frame(in: coordinateSpace).minY
            )
        }
        .onPreferenceChange(OffsetPreferenceKey.self) { value in
            offset = value
        }
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}