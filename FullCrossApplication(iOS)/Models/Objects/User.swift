import Foundation
import FirebaseFirestoreSwift

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let createdAt: Date
    let roles: [String]
    
    var uid: String {
        id ?? ""
    }
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    init(
        id: String? = nil,
        email: String = "",
        firstName: String = "",
        lastName: String = "",
        phoneNumber: String = "",
        createdAt: Date = Date(),
        roles: [String] = []
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.roles = roles
    }
}

// MARK: - Role Management
extension User {
    var isAdmin: Bool {
        roles.contains("admin")
    }
    
    var isModerator: Bool {
        roles.contains("moderator")
    }
    
    func hasRole(_ role: String) -> Bool {
        roles.contains(role.lowercased())
    }
}

// MARK: - Sample Data
extension User {
    static let sample = User(
        id: "user123",
        email: "john.doe@example.com",
        firstName: "John",
        lastName: "Doe",
        phoneNumber: "+1 (555) 123-4567",
        roles: ["user"]
    )
    
    static let samples = [
        sample,
        User(
            id: "admin456",
            email: "admin@fullcross.org",
            firstName: "Admin",
            lastName: "User",
            phoneNumber: "+1 (555) 987-6543",
            roles: ["admin", "user"]
        ),
        User(
            id: "mod789",
            email: "moderator@fullcross.org",
            firstName: "Mod",
            lastName: "User",
            phoneNumber: "+1 (555) 246-8135",
            roles: ["moderator", "user"]
        )
    ]
}

// MARK: - Date Formatting
extension User {
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    var memberSince: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Firestore Coding
extension User {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName
        case lastName
        case phoneNumber
        case createdAt
        case roles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        
        if let timestamp = try container.decode(TimeInterval.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp / 1000)
        } else {
            createdAt = Date()
        }
        
        roles = try container.decode([String].self, forKey: .roles)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(Int64(createdAt.timeIntervalSince1970 * 1000), forKey: .createdAt)
        try container.encode(roles, forKey: .roles)
    }
} 