// External dependencies versions:
// Combine: 5.5+
// Foundation: 5.5+

import Combine
import Foundation

/// ViewModelProtocol defines the base contract for all ViewModels in the MVVM architecture
/// Requirements addressed:
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
/// - SwiftUI + Combine (Technical Specification/Constraints for the AI to Generate a New iOS App/1)
protocol ViewModelProtocol: AnyObject {
    /// Published property to track loading state of the ViewModel
    /// Used to show/hide loading indicators in the view layer
    var isLoading: Published<Bool>.Publisher { get }
    
    /// Published property to handle error messages
    /// Allows propagating error states to the view layer for user feedback
    var errorMessage: Published<String?>.Publisher { get }
    
    /// Set to store and manage Combine subscriptions
    /// Prevents memory leaks by properly managing subscription lifecycles
    var cancellables: Set<AnyCancellable> { get set }
    
    /// Performs initial setup of the ViewModel
    /// Should be called when the ViewModel is created or view appears
    func initialize()
    
    /// Performs cleanup when ViewModel is being deallocated
    /// Ensures proper resource management and subscription cancellation
    func cleanup()
}

/// Default implementation for common ViewModel functionality
extension ViewModelProtocol {
    func cleanup() {
        // Cancel all active subscriptions to prevent memory leaks
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}