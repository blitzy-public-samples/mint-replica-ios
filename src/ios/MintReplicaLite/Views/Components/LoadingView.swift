// SwiftUI v5.5+
import SwiftUI
import struct Core.Utilities.Constants.Layout

// MARK: - Human Tasks
// 1. Verify that the app's Info.plist includes necessary accessibility descriptions
// 2. Test loading view with VoiceOver enabled to ensure proper screen reader support

/// A reusable loading indicator view component with customizable appearance
/// Addresses requirement: iOS Native Development - Technical Specification/1.2 Scope/Technical Implementation
/// Addresses requirement: Accessibility Features - Technical Specification/8.1.8 Accessibility Features
struct LoadingView: View {
    // MARK: - Properties
    
    /// Optional message to display below the loading indicator
    let message: String?
    
    /// Background color of the loading view
    let backgroundColor: Color
    
    /// Color of the loading spinner
    let spinnerColor: Color
    
    /// Whether the loading view should occupy the full screen
    let isFullScreen: Bool
    
    // MARK: - Initialization
    
    /// Creates a new loading view with customizable appearance
    /// - Parameters:
    ///   - message: Optional text to display below the spinner
    ///   - backgroundColor: Background color of the loading view (defaults to white)
    ///   - spinnerColor: Color of the loading spinner (defaults to blue)
    ///   - isFullScreen: Whether the view should occupy the full screen (defaults to false)
    init(
        message: String? = nil,
        backgroundColor: Color = .white,
        spinnerColor: Color = .blue,
        isFullScreen: Bool = false
    ) {
        self.message = message
        self.backgroundColor = backgroundColor
        self.spinnerColor = spinnerColor
        self.isFullScreen = isFullScreen
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Layout.standardPadding / 2) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: spinnerColor))
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Layout.standardPadding)
        .background(
            backgroundColor
                .opacity(0.95)
                .cornerRadius(8)
        )
        .frame(
            maxWidth: isFullScreen ? .infinity : nil,
            maxHeight: isFullScreen ? .infinity : nil
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
        .accessibilityTraits(.updatesFrequently)
        .accessibilityAddTraits(.isStatusElement)
    }
}

#if DEBUG
// MARK: - Preview Provider

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default loading view
            LoadingView()
                .previewDisplayName("Default")
            
            // Loading view with message
            LoadingView(
                message: "Loading your transactions...",
                backgroundColor: .gray.opacity(0.2),
                spinnerColor: .blue
            )
            .previewDisplayName("With Message")
            
            // Full screen loading view
            LoadingView(
                message: "Processing...",
                backgroundColor: .white,
                spinnerColor: .green,
                isFullScreen: true
            )
            .previewDisplayName("Full Screen")
            
            // Dark mode preview
            LoadingView(
                message: "Please wait...",
                backgroundColor: Color(.systemGray6),
                spinnerColor: .blue
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif