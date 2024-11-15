// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "./Views/Main/MainTabView"
import "./Views/Auth/LoginView"
import "./ViewModels/AuthViewModel"

/// Human Tasks:
/// 1. Verify app appearance settings match design system guidelines
/// 2. Test authentication state persistence across app launches
/// 3. Ensure proper navigation flow between authentication and main content

/// MintReplicaLiteApp is the main entry point for the iOS application
/// Requirements addressed:
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - MVVM Architecture (Technical Specification/Constraints for the AI to Generate a New iOS App/2)
/// - Mobile Navigation Structure (Technical Specification/8.1.1 Main Dashboard/Bottom Navigation)
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
@main
struct MintReplicaLiteApp: App {
    // MARK: - Properties
    
    @StateObject private var authViewModel = AuthViewModel()
    
    // MARK: - Initialization
    
    init() {
        configureAppAppearance()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.backgroundColor = .systemBackground
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Configure global tint color
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemBlue
    }
}

#if DEBUG
struct MintReplicaLiteApp_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        return Group {
            // Preview authenticated state
            MainTabView()
                .environmentObject(authViewModel)
                .previewDisplayName("Authenticated")
            
            // Preview unauthenticated state
            LoginView()
                .environmentObject(authViewModel)
                .previewDisplayName("Login")
        }
    }
}
#endif