// SwiftUI v5.5+
import SwiftUI

// MARK: - Human Tasks
/*
 * None required - This component is self-contained and works with SwiftUI out of the box
 */

// Import relative paths for internal dependencies
import "../../Core/Utilities/Constants"
import "../../Core/Extensions/View+Extensions"

/// A customizable progress view component for displaying progress bars throughout the app
/// Addresses requirements:
/// - Budget Status Display (Technical Specification/8.1.2 Main Dashboard)
/// - Goal Progress Tracking (Technical Specification/1.2 Scope/Core Features)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
struct CustomProgressView: View {
    // MARK: - Properties
    private let progress: Double
    private let label: String
    private let showPercentage: Bool
    private let progressColor: Color
    private let backgroundColor: Color
    private let height: CGFloat
    
    // MARK: - Initialization
    init(
        progress: Double,
        label: String = "",
        showPercentage: Bool = true,
        progressColor: Color = .accentColor,
        backgroundColor: Color = Color(.systemGray5),
        height: CGFloat = 24
    ) {
        self.progress = max(0, min(1, progress)) // Clamp between 0 and 1
        self.label = label
        self.showPercentage = showPercentage
        self.progressColor = progressColor
        self.backgroundColor = backgroundColor
        self.height = height
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Layout.standardPadding / 2) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .fill(backgroundColor)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(progress))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Percentage label
                    if showPercentage {
                        Text(formattedPercentage)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, Layout.standardPadding / 2)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .standardPadding()
        .frame(height: height)
        .accessibilityLabel("\(label) \(formattedPercentage)")
        .accessibilityValue(formattedPercentage)
        .accessibilityIdentifier("CustomProgressView")
    }
    
    // MARK: - Helper Methods
    private var formattedPercentage: String {
        let percentage = Int(round(progress * 100))
        return "\(percentage)%"
    }
}

#if DEBUG
// MARK: - Preview
struct CustomProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomProgressView(
                progress: 0.75,
                label: "Monthly Budget",
                showPercentage: true,
                progressColor: .blue
            )
            
            CustomProgressView(
                progress: 0.45,
                label: "Savings Goal",
                showPercentage: true,
                progressColor: .green
            )
            
            CustomProgressView(
                progress: 0.95,
                label: "Investment Target",
                showPercentage: true,
                progressColor: .orange,
                height: 32
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif