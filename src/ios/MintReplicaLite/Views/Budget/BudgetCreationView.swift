// External dependencies versions:
// SwiftUI: iOS 14.0+
// Combine: iOS 14.0+

import SwiftUI
import Combine

// Relative imports
import "../ViewModels/BudgetViewModel"
import "../Models/Budget"
import "../Core/Extensions/View+Extensions"

// MARK: - Human Tasks
// 1. Verify form validation feedback with VoiceOver
// 2. Test currency input formatting across different locales
// 3. Review keyboard handling and input field focus management
// 4. Validate category picker UI with large category lists

/// SwiftUI view for creating and editing budgets
/// Addresses requirements:
/// - Budget Creation and Monitoring (Technical Specification/1.2 Scope/Core Features)
/// - Budget Creation Interface (Technical Specification/8.1.4 Budget Creation/Edit)
struct BudgetCreationView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: BudgetViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var budgetName: String = ""
    @State private var amount: Double = 0.0
    @State private var selectedCategory: String = ""
    @State private var selectedPeriod: BudgetPeriod = .monthly
    @State private var showingCategoryPicker: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Form Validation
    
    private var isFormValid: Bool {
        !budgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        amount > 0 &&
        !selectedCategory.isEmpty
    }
    
    // MARK: - Initialization
    
    init(viewModel: BudgetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Budget Details")) {
                    TextField("Budget Name", text: $budgetName)
                        .textContentType(.name)
                        .disableAutocorrection(true)
                        .accessibilityLabel("Budget Name")
                    
                    HStack {
                        Text("$")
                        TextField("Amount", value: $amount, formatter: NumberFormatter.currency)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Budget Amount")
                    }
                }
                .standardPadding()
                
                Section(header: Text("Budget Period")) {
                    Picker("Period", selection: $selectedPeriod) {
                        Text("Weekly").tag(BudgetPeriod.weekly)
                        Text("Monthly").tag(BudgetPeriod.monthly)
                        Text("Custom").tag(BudgetPeriod.custom)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .accessibilityLabel("Budget Period Selection")
                }
                .standardPadding()
                
                Section(header: Text("Category")) {
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        HStack {
                            Text(selectedCategory.isEmpty ? "Select Category" : selectedCategory)
                                .foregroundColor(selectedCategory.isEmpty ? .gray : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .accessibilityLabel("Select Budget Category")
                }
                .standardPadding()
                
                Section {
                    Button(action: saveBudget) {
                        Text("Create Budget")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .disabled(!isFormValid)
                    .buttonStyle(BorderedButtonStyle())
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .accessibilityLabel("Create Budget Button")
                    .accessibilityHint(isFormValid ? "Double tap to create budget" : "Form is incomplete")
                }
                .standardPadding()
            }
            .cardStyle()
            .navigationTitle("Create Budget")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
            .loadingOverlay(viewModel.isLoading)
            .alert(item: Binding(
                get: { viewModel.errorMessage.map { ErrorAlert(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveBudget() {
        viewModel.createBudget(
            name: budgetName.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            category: selectedCategory,
            period: selectedPeriod
        )
        .receive(on: DispatchQueue.main)
        .sink { completion in
            if case .finished = completion {
                presentationMode.wrappedValue.dismiss()
            }
        } receiveValue: { _ in }
        .store(in: &cancellables)
    }
}

// MARK: - Supporting Views

private struct CategoryPickerView: View {
    @Binding var selectedCategory: String
    @Environment(\.presentationMode) private var presentationMode
    
    // Mock categories - In production, these would come from a service
    private let categories = [
        "Groceries",
        "Transportation",
        "Entertainment",
        "Utilities",
        "Shopping",
        "Healthcare",
        "Education"
    ]
    
    var body: some View {
        NavigationView {
            List(categories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(category)
                        Spacer()
                        if category == selectedCategory {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Supporting Types

private struct ErrorAlert: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Formatters

private extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}