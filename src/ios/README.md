# Mint Replica Lite iOS App

## Project Overview

Mint Replica Lite is a comprehensive personal financial management iOS application built using native Swift and SwiftUI frameworks. The app enables users to manage their finances through features like secure authentication, transaction tracking, budgeting, and investment monitoring.

## Technical Stack

- **Swift Version**: 5.5+
- **iOS Target**: 15.0+
- **Primary Frameworks**:
  - SwiftUI for UI development
  - Combine for reactive programming
  - CoreData for local persistence (mocked)

## Architecture

The application follows the MVVM (Model-View-ViewModel) architectural pattern with the following key components:

### Core Components
- **Views**: SwiftUI views implementing the user interface
  - `LoginView`: User authentication interface
  - `MainTabView`: Primary navigation container
  - `DashboardView`: Financial overview
  - `AccountsView`: Account management
  - `BudgetView`: Budget tracking
  - `InvestmentsView`: Portfolio monitoring

### ViewModels
- `AuthViewModel`: Manages authentication state
- `DashboardViewModel`: Handles dashboard data aggregation
- `AccountsViewModel`: Manages financial accounts
- `BudgetViewModel`: Controls budget operations
- `InvestmentsViewModel`: Handles investment tracking

### Patterns
- SwiftUI App Lifecycle
- Dependency Injection
- Observable Objects
- Combine Publishers/Subscribers

## Setup Instructions

1. **Prerequisites**:
   - Xcode 13.0 or later
   - iOS 15.0+ deployment target
   - Swift 5.5+

2. **Installation**:
   ```bash
   # Clone the repository
   git clone [repository-url]
   cd mint-replica-lite-ios
   
   # Open the project in Xcode
   open MintReplicaLite.xcodeproj
   ```

3. **Build and Run**:
   - Select your target device/simulator
   - Press Cmd + R to build and run

## Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI's declarative syntax
- Implement MVVM pattern consistently
- Keep views modular and reusable

### SwiftUI Best Practices
- Use `@State` for view-local state
- Implement `@ObservableObject` for ViewModels
- Utilize `@EnvironmentObject` for dependency injection
- Follow SwiftUI lifecycle methods

### Git Workflow
1. Create feature branch from `develop`
2. Implement changes following guidelines
3. Submit PR with detailed description
4. Address review comments
5. Merge after approval

## Mock Services

### Network Layer
- `MockAPIService`: Simulates network requests
- `MockAuthService`: Handles authentication flows
- `MockDataService`: Provides mock financial data

### Local Storage
- `MockStorageService`: Simulates local data persistence
- `MockCacheService`: Handles temporary data caching

## Project Structure

```
MintReplicaLite/
├── Views/
│   ├── Auth/
│   ├── Dashboard/
│   ├── Accounts/
│   ├── Budget/
│   └── Investments/
├── ViewModels/
│   ├── AuthViewModel/
│   ├── DashboardViewModel/
│   └── ...
├── Models/
│   ├── User/
│   ├── Account/
│   └── Transaction/
├── Services/
│   ├── MockAPI/
│   └── MockStorage/
└── Utils/
    ├── Extensions/
    └── Helpers/
```

## Dependencies

Managed through Swift Package Manager (SPM):

```swift
dependencies: [
    // Add dependencies as needed
]
```

## Contributing

1. **Code Standards**:
   - Follow Swift style guide
   - Write self-documenting code
   - Include inline documentation
   - Add relevant comments

2. **Pull Requests**:
   - Create feature branch
   - Write descriptive commit messages
   - Include test coverage
   - Update documentation
   - Request review from team members

3. **Review Process**:
   - Code review required
   - CI checks must pass
   - Documentation must be updated
   - Follow PR template

4. **Testing**:
   - Write unit tests for ViewModels
   - Include UI tests for critical flows
   - Test on multiple devices/iOS versions

## License

[Add License Information]

---
*Note: This is a mock implementation focusing on UI and ViewModels. Network and database layers are simulated through mock services.*