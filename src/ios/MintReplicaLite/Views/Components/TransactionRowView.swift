// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../../Models/Transaction"
import "../../Core/Extensions/View+Extensions"

// MARK: - Human Tasks
/*
 * 1. Verify color scheme adaptation for dark mode
 * 2. Test VoiceOver interaction flows
 * 3. Validate touch target sizes on different device sizes
 */

/// A SwiftUI view component that displays a single transaction row with consistent styling
/// Addresses requirements:
/// - Transaction Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct TransactionRowView: View {
    // MARK: - Properties
    
    let transaction: Transaction
    let onTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(transaction: Transaction, onTap: (() -> Void)? = nil) {
        self.transaction = transaction
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(transaction.formattedDate())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount())
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.amount < 0 ? .red : .green)
                
                if transaction.pending {
                    Text("Pending")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.2))
                        )
                }
            }
        }
        .standardPadding()
        .accessibleTapTarget()
        .contentShape(Rectangle()) // Makes entire row tappable
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.description), \(transaction.formattedAmount())")
        .accessibilityHint(
            "\(transaction.category), \(transaction.formattedDate())" +
            (transaction.pending ? ", Pending transaction" : "")
        )
        .accessibilityAddTraits(.isButton)
    }
}