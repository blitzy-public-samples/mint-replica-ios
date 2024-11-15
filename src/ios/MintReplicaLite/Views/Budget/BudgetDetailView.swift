// External dependencies versions:
// SwiftUI: iOS 14.0+
// Combine: iOS 14.0+

import SwiftUI
import Combine

// Relative imports
import "../../ViewModels/BudgetViewModel"
import "../../Models/Budget"
import "../Components/BudgetProgressCard"

// MARK: - Human Tasks
// 1. Test VoiceOver functionality across all interactive elements
// 2. Verify error handling feedback for failed budget operations
// 3. Test keyboard navigation in edit mode
// 4. Validate form validation behavior with various input scenarios

/// A view that displays detailed information about a specific budget with editing and deletion capabilities
/// Addresses requirements:
/// - Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
/// - Budget Status Display (Technical Specification/8.1.4 Budget Creation/Edit)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct BudgetDetailView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: BudgetViewModel
    let budget: Budget
    
    @State private var isEditMode: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var editedName: String
    @State private var editedAmount: Double
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    // MARK: - Initialization
    
    init(viewModel: BudgetViewModel, budget: Budget) {
        self.viewModel = viewModel
        self.budget = budget
        _editedName = State(initialValue: budget.name)
        _editedAmount = State(initialValue: budget.amount)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Progress Card
                    BudgetProgressCard(budget: budget)
                        .padding(.horizontal)
                        .accessibilityElement(children: .contain)
                    
                    // Edit Form
                    if isEditMode {
                        editForm
                    } else {
                        budgetDetails
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(budget.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !isEditMode {
                            Button(action: { isEditMode = true }) {
                                Image(systemName: "pencil")
                                    .accessibilityLabel("Edit Budget")
                            }
                        }
                        
                        Button(action: { showDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("Delete Budget")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditMode {
                        Button("Cancel") {
                            isEditMode = false
                            editedName = budget.name
                            editedAmount = budget.amount
                        }
                    }
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Budget"),
                    message: Text("Are you sure you want to delete this budget? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteBudget()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var editForm: some View {
        VStack(spacing: 16) {
            TextField("Budget Name", text: $editedName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .accessibilityLabel("Budget Name")
            
            HStack {
                Text("$")
                TextField("Amount", value: $editedAmount, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel("Budget Amount")
            }
            .padding(.horizontal)
            
            Button(action: saveBudgetChanges) {
                Text("Save Changes")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(editedName.isEmpty || editedAmount <= 0)
        }
    }
    
    private var budgetDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Spending History Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Spending History")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Current Period")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(budget.formattedSpent())
                        .font(.title2)
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            // Budget Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack {
                    Image(systemName: budget.isOverBudget() ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(budget.isOverBudget() ? .red : .green)
                    
                    Text(budget.isOverBudget() ? "Over Budget" : "Within Budget")
                        .foregroundColor(budget.isOverBudget() ? .red : .green)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveBudgetChanges() {
        guard editedName.trimmingCharacters(in: .whitespacesAndNewlines).count > 0,
              editedAmount > 0 else {
            errorMessage = "Please enter valid budget details"
            showErrorAlert = true
            return
        }
        
        // Create updated budget
        do {
            let updatedBudget = try Budget(
                id: budget.id,
                name: editedName,
                amount: editedAmount,
                category: budget.category,
                period: budget.period,
                startDate: budget.startDate,
                endDate: budget.endDate,
                spent: budget.spent,
                isActive: budget.isActive
            )
            
            viewModel.updateBudget(updatedBudget)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    }
                } receiveValue: { _ in
                    isEditMode = false
                    UIAccessibility.post(notification: .announcement, argument: "Budget updated successfully")
                }
                .store(in: &viewModel.cancellables)
            
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func deleteBudget() {
        viewModel.deleteBudget(budgetId: budget.id)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            } receiveValue: { _ in
                UIAccessibility.post(notification: .announcement, argument: "Budget deleted successfully")
            }
            .store(in: &viewModel.cancellables)
    }
}

#if DEBUG
struct BudgetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BudgetViewModel(budgetService: MockBudgetService())
        let previewBudget = try! Budget(
            id: "preview",
            name: "Sample Budget",
            amount: 1000.0,
            category: "Groceries",
            period: .monthly,
            startDate: Date(),
            endDate: Date().addingTimeInterval(2592000),
            spent: 750.0
        )
        
        BudgetDetailView(viewModel: viewModel, budget: previewBudget)
    }
}
#endif