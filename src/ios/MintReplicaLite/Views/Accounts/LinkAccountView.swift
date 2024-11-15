// SwiftUI v5.5+
import SwiftUI

// MARK: - Human Tasks
// 1. Verify Plaid integration configuration with backend team
// 2. Add analytics tracking for account linking events
// 3. Test accessibility features with VoiceOver

/// A SwiftUI view that provides the user interface for linking new financial accounts
/// Requirements addressed:
/// - Financial Institution Integration (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
struct LinkAccountView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: AccountViewModel
    @State private var selectedInstitutionId: String?
    @State private var selectedAccountType: Account.AccountType?
    @Environment(\.dismiss) private var dismiss
    
    // Mock financial institutions for demo purposes
    private let institutions = [
        ("chase", "Chase"),
        ("bofa", "Bank of America"),
        ("wells_fargo", "Wells Fargo"),
        ("citi", "Citibank")
    ]
    
    // MARK: - Initialization
    
    init() {
        _viewModel = StateObject(wrappedValue: AccountViewModel(accountService: MockAccountService()))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Institution Selection
                Section(header: Text("Select Financial Institution")) {
                    Picker("Institution", selection: $selectedInstitutionId) {
                        Text("Select an institution")
                            .foregroundColor(.secondary)
                            .tag(Optional<String>.none)
                        
                        ForEach(institutions, id: \.0) { id, name in
                            Text(name)
                                .tag(Optional(id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Account Type Selection
                Section(header: Text("Account Type")) {
                    Picker("Account Type", selection: $selectedAccountType) {
                        Text("Select account type")
                            .foregroundColor(.secondary)
                            .tag(Optional<Account.AccountType>.none)
                        
                        ForEach(Account.AccountType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized)
                                .tag(Optional(type))
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Link Account Button
                Section {
                    Button(action: linkAccount) {
                        HStack {
                            Spacer()
                            Text("Link Account")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Link Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(
                        message: "Connecting to your bank...",
                        backgroundColor: .white,
                        spinnerColor: .blue
                    )
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private var isFormValid: Bool {
        selectedInstitutionId != nil && selectedAccountType != nil
    }
    
    private func linkAccount() {
        guard let institutionId = selectedInstitutionId,
              let accountType = selectedAccountType else {
            return
        }
        
        Task {
            if let _ = await viewModel.linkNewAccount(
                institutionId: institutionId,
                accountType: accountType
            ) {
                dismiss()
            }
        }
    }
}

#if DEBUG
// MARK: - Preview Provider

struct LinkAccountView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state
            LinkAccountView()
                .previewDisplayName("Default")
            
            // Loading state
            LinkAccountView()
                .previewDisplayName("Loading")
                .onAppear {
                    let vm = AccountViewModel(accountService: MockAccountService())
                    vm.isLoading = true
                }
            
            // Error state
            LinkAccountView()
                .previewDisplayName("Error")
                .onAppear {
                    let vm = AccountViewModel(accountService: MockAccountService())
                    vm.errorMessage = "Failed to connect to institution"
                }
            
            // Dark mode
            LinkAccountView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif