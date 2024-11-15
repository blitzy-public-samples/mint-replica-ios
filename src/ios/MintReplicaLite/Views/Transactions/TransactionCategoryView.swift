// SwiftUI v5.5+
// Combine v5.5+
import SwiftUI
import Combine

// Relative imports
import "../../Models/Transaction"
import "../../ViewModels/TransactionViewModel"
import "../Components/LoadingView"

// MARK: - Human Tasks
/*
 * 1. Verify accessibility labels with UX team
 * 2. Review category list with product team for completeness
 * 3. Add unit tests for category selection logic
 */

/// A view that handles transaction category selection and management
/// Requirements addressed:
/// - Transaction Categorization (Technical Specification/1.2 Scope/Core Features)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
struct TransactionCategoryView: View {
    // MARK: - Properties
    
    let transaction: Transaction
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String
    @State private var showingConfirmation = false
    @State private var errorMessage: String?
    
    // MARK: - Constants
    
    private let categories = [
        "Food & Dining",
        "Shopping",
        "Transportation",
        "Bills & Utilities",
        "Entertainment",
        "Health & Fitness",
        "Travel",
        "Education",
        "Business",
        "Personal Care",
        "Home",
        "Gifts & Donations",
        "Investments",
        "Income",
        "Transfer",
        "Other"
    ]
    
    // MARK: - Initialization
    
    init(transaction: Transaction, viewModel: TransactionViewModel) {
        self.transaction = transaction
        self.viewModel = viewModel
        _selectedCategory = State(initialValue: transaction.category)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            showingConfirmation = true
                        }) {
                            HStack {
                                Text(category)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if category == selectedCategory {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Select Category")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .confirmationDialog(
                    "Change category to \(selectedCategory)?",
                    isPresented: $showingConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Confirm") {
                        updateCategory()
                    }
                    Button("Cancel", role: .cancel) {
                        selectedCategory = transaction.category
                    }
                }
                .alert("Error", isPresented: .constant(errorMessage != nil)) {
                    Button("OK") {
                        errorMessage = nil
                    }
                } message: {
                    if let error = errorMessage {
                        Text(error)
                    }
                }
                
                if viewModel.isLoading {
                    LoadingView(
                        message: "Updating category...",
                        backgroundColor: .white,
                        spinnerColor: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateCategory() {
        viewModel.categorizeTransaction(
            transactionId: transaction.id,
            category: selectedCategory
        )
        
        // Observe the error message publisher
        viewModel.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { error in
                if let error = error {
                    errorMessage = error
                } else {
                    dismiss()
                }
            }
            .store(in: &viewModel.cancellables)
    }
}

#if DEBUG
struct TransactionCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockTransaction = Transaction(
            id: "123",
            accountId: "456",
            amount: 42.50,
            date: Date(),
            description: "Coffee Shop",
            category: "Food & Dining",
            pending: false
        )
        
        let mockViewModel = TransactionViewModel(
            accountId: "456",
            transactionService: MockTransactionService()
        )
        
        TransactionCategoryView(
            transaction: mockTransaction,
            viewModel: mockViewModel
        )
    }
}
#endif