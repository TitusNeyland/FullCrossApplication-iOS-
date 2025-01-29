import Foundation

public struct FCUser: Identifiable, Equatable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let phoneNumber: String
    public let roles: Set<String>
    
    public var isAdmin: Bool {
        roles.contains("admin")
    }
    
    public init(
        id: String,
        email: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        roles: Set<String>
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.roles = roles
    }
}
