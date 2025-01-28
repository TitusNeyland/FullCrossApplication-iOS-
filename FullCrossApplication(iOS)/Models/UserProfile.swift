import Foundation

public struct UserProfile: Identifiable {
    public let id: String
    public let firstName: String
    public let lastName: String
    public let phoneNumber: String
    public var friendshipStatus: FriendshipStatus = .none
    
    public var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    public init(id: String, firstName: String, lastName: String, phoneNumber: String, friendshipStatus: FriendshipStatus = .none) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.friendshipStatus = friendshipStatus
    }
}


