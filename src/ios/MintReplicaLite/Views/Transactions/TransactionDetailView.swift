// SwiftUI v5.5+
// Combine v5.5+
import SwiftUI
import Combine

// Relative imports
import "../../Models/Transaction"
import "../../ViewModels/TransactionViewModel"
import "../Components/CustomNavigationBar"

// MARK: - Human Tasks
/*
 * 1. Review category selection UI/UX with design team
 * 2. Implement accessibility labels for transaction details
 * 3. Add haptic feedback for successful updates
 */

/// A detailed view of a single transaction with editing capabilities
/// Requirements addressed:
/// - Transaction Tracking (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
struct TransactionDetailView: View {
    // MARK: - Properties
    
    let transaction: Transaction
    @ObservedObject var viewModel: TransactionViewModel
    @State private var isEditingCategory = false
    @State private var noteText: String
    @Environment(\.presentationMode) private var presentationMode
    
    // Available transaction categories
    private let categories = [
        "Food & Dining",
        "Shopping",
        "Transportation",
        "Bills & Utilities",
        "Entertainment",
        "Health & Fitness",
        "Travel",
        "Income",
        "Other"
    ]
    
    // MARK: - Initialization
    
    init(transaction: Transaction, viewModel: TransactionViewModel) {
        self.transaction = transaction
        self.viewModel = viewModel
        self._noteText = State(initialValue: transaction.notes ?? "")
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(
                title: "Transaction Details",
                showBackButton: true,
                onBackTapped: {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Amount section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(transaction.formattedAmount())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(transaction.amount >= 0 ? .green : .red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Date and merchant section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Date")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(transaction.formattedDate())
                                .font(.body)
                        }
                        
                        if let merchantName = transaction.merchantName {
                            HStack {
                                Text("Merchant")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(merchantName)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Category section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Category")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                isEditingCategory.toggle()
                            }) {
                                Text(isEditingCategory ? "Done" : "Edit")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if isEditingCategory {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
                                        Button(action: {
                                            updateCategory(category)
                                        }) {
                                            Text(category)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    transaction.category == category ?
                                                        Color.blue : Color(UIColor.tertiarySystemBackground)
                                                )
                                                .foregroundColor(
                                                    transaction.category == category ?
                                                        .white : .primary
                                                )
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text(transaction.category)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Notes section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                        
                        TextEditor(text: $noteText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(8)
                        
                        Button(action: saveNote) {
                            Text("Save Note")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(noteText == transaction.notes)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .alert(item: .constant(viewModel.errorMessage)) { error in
            Alert(
                title: Text("Error"),
                message: Text(error),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay(
            Group {
                if viewModel.isLoading.value {
                    Color(UIColor.systemBackground)
                        .opacity(0.8)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
        )
    }
    
    // MARK: - Private Methods
    
    private func saveNote() {
        viewModel.addNote(transactionId: transaction.id, note: noteText)
    }
    
    private func updateCategory(_ newCategory: String) {
        viewModel.categorizeTransaction(transactionId: transaction.id, category: newCategory)
        isEditingCategory = false
    }
}

#if DEBUG
struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockTransaction = Transaction(
            id: "123",
            accountId: "456",
            amount: -42.50,
            date: Date(),
            description: "Coffee Shop",
            category: "Food & Dining",
            pending: false,
            merchantName: "Starbucks",
            notes: "Team meeting"
        )
        
        TransactionDetailView(
            transaction: mockTransaction,
            viewModel: TransactionViewModel(
                accountId: "456",
                transactionService: MockTransactionService()
            )
        )
    }
}
#endif