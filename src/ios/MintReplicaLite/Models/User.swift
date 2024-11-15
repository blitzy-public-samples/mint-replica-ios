// Foundation v5.5+
import Foundation
// Import relative path for UserDefaultsKeys
import "../Core/Utilities/Constants"

/// Core User model representing an authenticated user in the MintReplicaLite application
/// Addresses requirements:
/// - Secure User Authentication (Technical Specification/1.2 Scope/Core Features)
/// - iOS Native Development (Technical Specification/1.2 Scope/Technical Implementation)
/// - User Profile Management (Technical Specification/6.1.1 Core Application Components)
class User: Codable, Identifiable, Equatable {
    // MARK: - Properties
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    var lastLoginDate: Date
    let createdDate: Date
    var isEmailVerified: Bool
    var hasBiometricEnabled: Bool
    var profileImageUrl: String?
    var preferredCurrency: String
    var notificationsEnabled: Bool
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName
        case lastName
        case lastLoginDate
        case createdDate
        case isEmailVerified
        case hasBiometricEnabled
        case profileImageUrl
        case preferredCurrency
        case notificationsEnabled
    }
    
    // MARK: - Initialization
    init(id: String, email: String, firstName: String, lastName: String, preferredCurrency: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.preferredCurrency = preferredCurrency
        
        // Set default values for dates
        self.lastLoginDate = Date()
        self.createdDate = Date()
        
        // Set default values for flags
        self.isEmailVerified = false
        self.hasBiometricEnabled = false
        self.notificationsEnabled = true
        
        // Set optional values
        self.profileImageUrl = nil
    }
    
    // MARK: - Public Methods
    /// Returns the user's full name by combining first and last name
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    /// Updates the user's last login date to current date
    func updateLastLoginDate() {
        self.lastLoginDate = Date()
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.lastLoginDate == rhs.lastLoginDate &&
               lhs.createdDate == rhs.createdDate &&
               lhs.isEmailVerified == rhs.isEmailVerified &&
               lhs.hasBiometricEnabled == rhs.hasBiometricEnabled &&
               lhs.profileImageUrl == rhs.profileImageUrl &&
               lhs.preferredCurrency == rhs.preferredCurrency &&
               lhs.notificationsEnabled == rhs.notificationsEnabled
    }
}