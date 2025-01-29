import Foundation

public struct FCUser: Identifiable, Equatable {
    public let id: String
    public let email: String
    public let roles: Set<String>
    
    public var isAdmin: Bool {
        roles.contains("admin")
    }
    
    public init(id: String, email: String, roles: Set<String>) {
        self.id = id
        self.email = email
        self.roles = roles
    }
}
