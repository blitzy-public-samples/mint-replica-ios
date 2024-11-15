// SwiftUI v5.5+
import SwiftUI
import "../Utilities/Constants"

// MARK: - Human Tasks
/*
 * None required - This file contains self-contained view modifiers that work with SwiftUI out of the box
 */

// MARK: - View Extensions
/// Extension providing common modifiers and styling functions for consistent UI implementation
/// Addresses requirements:
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
extension View {
    /// Applies standard padding to the view using the app's design system
    /// - Returns: Modified view with standard padding applied
    func standardPadding() -> some View {
        self.padding(Layout.standardPadding)
    }
    
    /// Ensures view meets minimum tap target size requirements for accessibility
    /// Addresses requirement: Accessibility Features - Minimum touch target size
    /// - Returns: Modified view with minimum tap target size
    func accessibleTapTarget() -> some View {
        self
            .frame(minWidth: Layout.minimumTouchTarget, minHeight: Layout.minimumTouchTarget, alignment: .center)
            .contentShape(Rectangle()) // Ensures the entire frame is tappable
    }
    
    /// Conditionally applies a modifier to the view based on a condition
    /// - Parameters:
    ///   - condition: Boolean condition determining if modifier should be applied
    ///   - modifier: ViewModifier to apply when condition is true
    /// - Returns: View with conditionally applied modifier
    func conditionalModifier<T: ViewModifier>(_ condition: Bool, _ modifier: T) -> some View {
        Group {
            if condition {
                self.modifier(modifier)
            } else {
                self
            }
        }
    }
    
    /// Applies standard card styling used throughout the app
    /// - Returns: Modified view with card styling applied
    func cardStyle() -> some View {
        self
            .background(Color(UIColor.systemBackground))
            .cornerRadius(Layout.cornerRadius)
            .shadow(color: Color(UIColor.systemGray).opacity(0.1), 
                   radius: 8, 
                   x: 0, 
                   y: 2)
            .padding(Layout.cardPadding)
    }
    
    /// Adds a loading overlay with activity indicator when loading state is true
    /// Addresses requirement: Accessibility Features - Screen reader compatibility
    /// - Parameter isLoading: Boolean indicating whether loading state is active
    /// - Returns: View with conditional loading overlay
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color(.black)
                            .opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .accessibilityIdentifier("LoadingOverlay")
                    .accessibilityLabel("Loading")
                }
            }
        )
    }
}