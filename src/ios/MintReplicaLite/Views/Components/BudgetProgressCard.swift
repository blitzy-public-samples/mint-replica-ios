// SwiftUI v5.5+
import SwiftUI

// Import relative dependencies
import "../../Models/Budget"
import "./ProgressView"
import "../../Core/Extensions/Color+Extensions"

// MARK: - Human Tasks
// 1. Verify VoiceOver testing with different budget states
// 2. Test color contrast ratios in different display modes
// 3. Validate dynamic type scaling behavior

/// A reusable card component that displays budget progress information
/// Addresses requirements:
/// - Budget Progress Visualization (Technical Specification/8.1.2 Main Dashboard)
/// - Budget Status Display (Technical Specification/8.1.4 Budget Creation/Edit)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct BudgetProgressCard: View {
    // MARK: - Properties
    
    private let budget: Budget
    private let isCompact: Bool
    private let progressColor: Color
    
    // MARK: - Initialization
    
    init(budget: Budget, isCompact: Bool = false) {
        self.budget = budget
        self.isCompact = isCompact
        self.progressColor = Self.determineProgressColor(budget: budget)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category name and progress percentage
            HStack {
                Text(budget.category)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.text)
                
                Spacer()
                
                Text(budget.formattedProgress())
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.textSecondary)
            }
            
            // Progress bar
            CustomProgressView(
                progress: budget.spentPercentage() / 100,
                progressColor: progressColor,
                height: isCompact ? 8 : 12
            )
            
            // Detailed amounts (only shown in expanded mode)
            if !isCompact {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Spent")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.textSecondary)
                        Text(budget.formattedSpent())
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.text)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Budget")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.textSecondary)
                        Text(budget.formattedAmount())
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.text)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(createAccessibilityLabel())
        .accessibilityHint(createAccessibilityHint())
    }
    
    // MARK: - Helper Methods
    
    /// Determines the appropriate color based on budget progress
    /// Addresses requirement: Budget Status Display (Technical Specification/8.1.4 Budget Creation/Edit)
    private static func determineProgressColor(budget: Budget) -> Color {
        if budget.isOverBudget() {
            return .error
        }
        
        let percentage = budget.spentPercentage()
        if percentage >= 90 {
            return .warning
        } else if percentage >= 75 {
            return .warning.opacity(0.8)
        }
        return .success
    }
    
    /// Creates an accessibility label combining category and progress information
    /// Addresses requirement: Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
    private func createAccessibilityLabel() -> String {
        return "\(budget.category) budget: \(budget.formattedSpent()) spent of \(budget.formattedAmount())"
    }
    
    /// Creates an accessibility hint based on budget status
    /// Addresses requirement: Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
    private func createAccessibilityHint() -> String {
        if budget.isOverBudget() {
            return "Over budget"
        }
        let percentage = budget.spentPercentage()
        if percentage >= 90 {
            return "Near budget limit"
        }
        return "Within budget"
    }
}

#if DEBUG
struct BudgetProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBudget = try! Budget(
            id: "preview",
            name: "Sample Budget",
            amount: 1000.0,
            category: "Groceries",
            period: .monthly,
            startDate: Date(),
            endDate: Date().addingTimeInterval(2592000),
            spent: 750.0
        )
        
        Group {
            BudgetProgressCard(budget: sampleBudget, isCompact: false)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Expanded")
            
            BudgetProgressCard(budget: sampleBudget, isCompact: true)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Compact")
        }
    }
}
#endif