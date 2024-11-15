// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../../Models/Account"
import "../../Core/Extensions/Double+Extensions"
import "../../Core/Extensions/View+Extensions"

// MARK: - Human Tasks
// 1. Verify VoiceOver labels and hints with accessibility team
// 2. Test touch target size across different device sizes
// 3. Validate color contrast ratios for accessibility compliance

/// A SwiftUI view component that displays account information in a card format
/// Addresses requirements:
/// - Account Display (Technical Specification/8.1.2 Main Dashboard)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - Accessibility (Technical Specification/8.1.8 Accessibility Features)
struct AccountCardView: View {
    // MARK: - Properties
    
    let account: Account
    let isSelected: Bool
    let onTap: (Account) -> Void
    
    // MARK: - Initialization
    
    init(account: Account, isSelected: Bool = false, onTap: @escaping (Account) -> Void) {
        self.account = account
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Account Type Header
            HStack {
                accountTypeIcon
                Text(account.accountType.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Balance
            Text(account.formattedBalance())
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Last Synced Date
            Text("Last updated: \(account.formattedLastSynced())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .cardStyle()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2),
                       radius: isSelected ? 8 : 4,
                       x: 0,
                       y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap(account)
        }
        .accessibleTapTarget()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.accountType.rawValue.capitalized) account with balance \(account.formattedBalance())")
        .accessibilityHint("Double tap to select account")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var accountTypeIcon: some View {
        switch account.accountType {
        case .checking:
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(.blue)
        case .savings:
            Image(systemName: "banknote.fill")
                .foregroundColor(.green)
        case .investment:
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .foregroundColor(.purple)
        case .credit:
            Image(systemName: "creditcard.fill")
                .foregroundColor(.red)
        }
    }
}