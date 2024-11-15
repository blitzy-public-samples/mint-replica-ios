// SwiftUI v5.5+
import SwiftUI

// MARK: - Human Tasks
/*
 * None required - This component is self-contained and works with SwiftUI out of the box
 */

/// A reusable SwiftUI view component for displaying error states with consistent styling
/// Addresses requirements:
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct ErrorView: View {
    // MARK: - Properties
    private let message: String
    private let title: String?
    private let retryAction: (() -> Void)?
    private let retryButtonText: String
    
    // MARK: - Initialization
    init(
        message: String,
        title: String? = nil,
        retryAction: (() -> Void)? = nil,
        retryButtonText: String
    ) {
        self.message = message
        self.title = title
        self.retryAction = retryAction
        self.retryButtonText = retryButtonText
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .center, spacing: Layout.standardPadding) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: Layout.iconSize * 2))
                .foregroundColor(.red)
                .accessibilityHidden(true)
            
            // Title (if provided)
            if let title = title {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .accessibilityLabel(title)
                    .accessibilityAddTraits(.isHeader)
            }
            
            // Error Message
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .accessibilityLabel(message)
                .accessibilityAddTraits(.isStaticText)
            
            // Retry Button (if action provided)
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Text(retryButtonText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, Layout.standardPadding * 2)
                        .padding(.vertical, Layout.standardPadding)
                        .background(Color.blue)
                        .cornerRadius(Layout.cornerRadius)
                }
                .accessibleTapTarget()
                .accessibilityLabel(retryButtonText)
                .accessibilityHint("Double tap to try again")
                .accessibilityAddTraits(.isButton)
            }
        }
        .standardPadding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ErrorView")
    }
}

#if DEBUG
// MARK: - Preview Provider
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Basic error view
            ErrorView(
                message: "Something went wrong. Please try again later.",
                retryButtonText: "Retry"
            )
            
            // Error view with title and retry action
            ErrorView(
                message: "Unable to load data. Check your internet connection.",
                title: "Connection Error",
                retryAction: { print("Retry tapped") },
                retryButtonText: "Try Again"
            )
            .preferredColorScheme(.dark)
        }
    }
}
#endif