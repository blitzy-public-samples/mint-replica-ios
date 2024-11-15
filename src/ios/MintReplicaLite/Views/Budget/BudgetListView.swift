// SwiftUI v5.5+
import SwiftUI
// Combine v5.5+
import Combine

// Relative imports
import "../../Models/Budget"
import "../../ViewModels/BudgetViewModel"
import "../Components/BudgetProgressCard"
import "../Components/LoadingView"
import "../Components/ErrorView"
import "../../Core/Extensions/View+Extensions"

// MARK: - Human Tasks
// 1. Test VoiceOver navigation flow through budget list
// 2. Verify dynamic type scaling for all text elements
// 3. Test filter picker interaction with VoiceOver
// 4. Validate search performance with large budget lists

/// Main view for displaying and managing user budgets with filtering capabilities
/// Addresses requirements:
/// - Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
/// - Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
struct BudgetListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showingAddBudget = false
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    
    private let filterOptions = ["All", "Monthly", "Weekly", "Custom"]
    
    // MARK: - Computed Properties
    
    private var filteredBudgets: [Budget] {
        var filtered = viewModel.budgets
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { budget in
                budget.name.localizedCaseInsensitiveContains(searchText) ||
                budget.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply period filter
        if selectedFilter != "All" {
            filtered = filtered.filter { budget in
                budget.period == BudgetPeriod(rawValue: selectedFilter.lowercased())
            }
        }
        
        return filtered
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                        .standardPadding()
                    
                    // Filter Picker
                    filterPicker
                        .standardPadding()
                    
                    // Budget List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredBudgets, id: \.id) { budget in
                                NavigationLink(
                                    destination: Text("Budget Detail") // Placeholder for BudgetDetailView
                                ) {
                                    BudgetProgressCard(budget: budget)
                                        .cardStyle()
                                        .accessibleTapTarget()
                                }
                            }
                        }
                        .standardPadding()
                    }
                    
                    // Add Budget Button
                    addBudgetButton
                        .standardPadding()
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    LoadingView(
                        message: "Loading budgets...",
                        backgroundColor: .white,
                        spinnerColor: .blue
                    )
                }
                
                // Error View
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        title: "Error",
                        retryAction: { viewModel.fetchBudgets() },
                        retryButtonText: "Try Again"
                    )
                }
            }
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search budgets", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel("Search budgets")
        }
    }
    
    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(filterOptions, id: \.self) { option in
                Text(option)
                    .tag(option)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .accessibilityLabel("Filter budgets by period")
    }
    
    private var addBudgetButton: some View {
        Button(action: { showingAddBudget = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Budget")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .accessibleTapTarget()
        .accessibilityLabel("Add new budget")
        .sheet(isPresented: $showingAddBudget) {
            Text("Add Budget") // Placeholder for AddBudgetView
        }
    }
}

#if DEBUG
struct BudgetListView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetListView()
    }
}
#endif