// SwiftUI v5.5+
import SwiftUI

// MARK: - Human Tasks
/*
 * None required - This component works with SwiftUI out of the box
 */

// Import relative paths for internal dependencies
import "../../Core/Utilities/Constants"
import "../../Core/Extensions/View+Extensions"

/// A custom navigation bar component providing consistent navigation styling and accessibility features
/// Addresses requirements:
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - Navigation Structure (Technical Specification/8.1.1 Mobile Navigation Structure)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct CustomNavigationBar: View {
    // MARK: - Properties
    let title: String
    let showBackButton: Bool
    let onBackTapped: (() -> Void)?
    let rightBarButton: AnyView?
    
    // MARK: - Initialization
    init(
        title: String,
        showBackButton: Bool = true,
        onBackTapped: (() -> Void)? = nil,
        rightBarButton: AnyView? = nil
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBackTapped = onBackTapped
        self.rightBarButton = rightBarButton
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: Layout.standardPadding) {
            // Back button
            if showBackButton {
                Button(action: {
                    onBackTapped?()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                        .imageScale(.large)
                }
                .accessibilityLabel("Back")
                .accessibilityAddTraits(.isButton)
                .accessibleTapTarget()
            }
            
            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            // Right bar button with placeholder if not provided
            if let rightButton = rightBarButton {
                rightButton
                    .accessibleTapTarget()
            } else {
                // Empty spacer to maintain layout when no right button
                Spacer()
                    .frame(width: Layout.minimumTouchTarget)
            }
        }
        .standardPadding()
        .frame(height: Layout.minimumTouchTarget)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: Color.black.opacity(0.1),
                       radius: 8,
                       x: 0,
                       y: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("CustomNavigationBar")
    }
}

#if DEBUG
// MARK: - Preview
struct CustomNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Preview with back button and right button
            CustomNavigationBar(
                title: "Dashboard",
                showBackButton: true,
                onBackTapped: {},
                rightBarButton: AnyView(
                    Button(action: {}) {
                        Image(systemName: "gear")
                            .foregroundColor(.primary)
                    }
                )
            )
            
            // Preview without back button
            CustomNavigationBar(
                title: "Settings",
                showBackButton: false
            )
            
            Spacer()
        }
    }
}
#endif