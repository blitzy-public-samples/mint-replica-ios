// SwiftUI v5.5+
import SwiftUI

// Relative imports
import "./DashboardView"
import "../Accounts/AccountsListView"
import "../Budget/BudgetListView"
import "../Goals/GoalsListView"
import "../Settings/SettingsView"

/// Main tab view container implementing bottom navigation with accessibility support
/// Addresses requirements:
/// - Mobile Navigation Structure (Technical Specification/8.1.1 Main Dashboard/Bottom Navigation)
/// - Mobile Responsive Design (Technical Specification/8.1.7 Mobile Responsive Considerations)
/// - Accessibility Features (Technical Specification/8.1.8 Accessibility Features)
struct MainTabView: View {
    // MARK: - Properties
    
    @State private var selectedTab: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
                .tag(0)
                .accessibilityLabel("Dashboard tab")
            
            AccountsListView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Accounts")
                }
                .tag(1)
                .accessibilityLabel("Accounts tab")
            
            BudgetListView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Budgets")
                }
                .tag(2)
                .accessibilityLabel("Budgets tab")
            
            GoalsListView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(3)
                .accessibilityLabel("Goals tab")
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("More")
                }
                .tag(4)
                .accessibilityLabel("More tab")
        }
        .accentColor(.blue)
        .onAppear {
            // Configure tab bar appearance for accessibility
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            
            // Ensure minimum touch target size of 44x44 points
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
#endif