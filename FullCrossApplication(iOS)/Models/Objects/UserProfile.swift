import Foundation

enum FriendshipStatus: String, Codable, CaseIterable {
    case none = "NONE"
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case declined = "DECLINED"
    
    var displayText: String {
        switch self {
        case .none:
            return "Add Friend"
        case .pending:
            return "Request Pending"
        case .accepted:
            return "Friends"
        case .declined:
            return "Request Declined"
        }
    }
    
    var iconName: String {
        switch self {
        case .none:
            return "person.badge.plus"
        case .pending:
            return "clock"
        case .accepted:
            return "person.2.fill"
        case .declined:
            return "person.badge.minus"
        }
    }
}

struct UserProfile: Identifiable, Codable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let friendshipStatus: FriendshipStatus
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    init(
        id: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        friendshipStatus: FriendshipStatus = .none
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.friendshipStatus = friendshipStatus
    }
}

// MARK: - Sample Data
extension UserProfile {
    static let sample = UserProfile(
        id: "user123",
        firstName: "John",
        lastName: "Doe",
        phoneNumber: "+1 (555) 123-4567",
        friendshipStatus: .none
    )
    
    static let samples = [
        sample,
        UserProfile(
            id: "user456",
            firstName: "Jane",
            lastName: "Smith",
            phoneNumber: "+1 (555) 987-6543",
            friendshipStatus: .pending
        ),
        UserProfile(
            id: "user789",
            firstName: "Bob",
            lastName: "Wilson",
            phoneNumber: "+1 (555) 246-8135",
            friendshipStatus: .accepted
        )
    ]
}

// MARK: - UI Helpers
extension UserProfile {
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    var formattedPhoneNumber: String? {
        // Basic phone formatting - you might want to use a more sophisticated formatter
        guard phoneNumber.count >= 10 else { return phoneNumber }
        let digits = phoneNumber.filter { $0.isNumber }
        guard digits.count >= 10 else { return phoneNumber }
        
        let index = digits.index(digits.startIndex, offsetBy: min(10, digits.count))
        let tenDigits = String(digits[..<index])
        
        return tenDigits.replacingOccurrences(
            of: "(\\d{3})(\\d{3})(\\d{4})",
            with: "($1) $2-$3",
            options: .regularExpression
        )
    }
}

// MARK: - Friendship Management
extension UserProfile {
    var canSendFriendRequest: Bool {
        friendshipStatus == .none || friendshipStatus == .declined
    }
    
    var isFriend: Bool {
        friendshipStatus == .accepted
    }
    
    var hasPendingRequest: Bool {
        friendshipStatus == .pending
    }
} 