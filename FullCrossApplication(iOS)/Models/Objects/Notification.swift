import Foundation

struct Notification: Identifiable, Codable, Equatable {
    let id: String
    let type: NotificationType
    let fromUserId: String
    let fromUserName: String
    let timestamp: Date
    let read: Bool
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType = .friendRequest,
        fromUserId: String = "",
        fromUserName: String = "",
        timestamp: Date = Date(),
        read: Bool = false
    ) {
        self.id = id
        self.type = type
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.timestamp = timestamp
        self.read = read
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case friendRequest = "FRIEND_REQUEST"
    
    var title: String {
        switch self {
        case .friendRequest:
            return "Friend Request"
        }
    }
    
    var iconName: String {
        switch self {
        case .friendRequest:
            return "person.badge.plus"
        }
    }
}

// MARK: - Sample Data
extension Notification {
    static let sample = Notification(
        fromUserName: "John Smith",
        fromUserId: "user123",
        type: .friendRequest
    )
    
    static let samples = [
        sample,
        Notification(
            fromUserName: "Sarah Wilson",
            fromUserId: "user456",
            type: .friendRequest,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            read: true
        )
    ]
}

// MARK: - Date Formatting
extension Notification {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var message: String {
        switch type {
        case .friendRequest:
            return "\(fromUserName) sent you a friend request"
        }
    }
} 