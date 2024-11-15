// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "../../Models/Goal"
import "./ProgressView"
import "../../Core/Extensions/View+Extensions"

/// A reusable card component that displays financial goal progress information
/// Addresses requirements:
/// - Financial Goal Setting (Technical Specification/1.1 System Overview/Core Features)
/// - Goal Progress Visualization (Technical Specification/8.1.2 Main Dashboard)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct GoalProgressCard: View {
    // MARK: - Properties
    
    private let goal: Goal
    private let isInteractive: Bool
    private let onTap: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        goal: Goal,
        isInteractive: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.goal = goal
        self.isInteractive = isInteractive
        self.onTap = onTap
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Goal name
            Text(goal.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Amount progress
            HStack {
                Text(goal.formattedCurrentAmount())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("of")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(goal.formattedTargetAmount())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            CustomProgressView(
                progress: goal.calculateProgress() / 100,
                label: "",
                showPercentage: true,
                progressColor: .accentColor,
                height: 8
            )
            
            // Target date
            Text("Target: \(goal.formattedTargetDate())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .cardStyle()
        .conditionalModifier(isInteractive) {
            Button(action: { onTap?() }) {
                EmptyView()
            }
            .buttonStyle(.plain)
        }
        .accessibleTapTarget()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name) goal")
        .accessibilityValue("""
            Current amount \(goal.formattedCurrentAmount()) of \
            \(goal.formattedTargetAmount()). \
            \(Int(goal.calculateProgress()))% complete. \
            Target date \(goal.formattedTargetDate())
            """)
        .accessibilityHint(isInteractive ? "Double tap to view goal details" : "")
        .accessibilityAddTraits(isInteractive ? .isButton : [])
    }
}

#if DEBUG
// MARK: - Preview
struct GoalProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Interactive card
            GoalProgressCard(
                goal: try! Goal(
                    id: "1",
                    name: "Emergency Fund",
                    description: "6 months of expenses",
                    targetAmount: 15000,
                    currentAmount: 5000,
                    targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())!,
                    category: .emergency
                ),
                isInteractive: true,
                onTap: {}
            )
            
            // Non-interactive card
            GoalProgressCard(
                goal: try! Goal(
                    id: "2",
                    name: "New Car",
                    description: "Save for down payment",
                    targetAmount: 10000,
                    currentAmount: 7500,
                    targetDate: Calendar.current.date(byAdding: .month, value: 12, to: Date())!,
                    category: .savings
                ),
                isInteractive: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif