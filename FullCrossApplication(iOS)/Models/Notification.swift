import Foundation

struct Notification: Identifiable {
    let id: String
    let type: NotificationType
    let fromUserId: String
    let fromUserName: String
    let timestamp: Date
    let read: Bool
}

enum NotificationType: String, Codable {
    case friendRequest = "FRIEND_REQUEST"
    // Add other notification types as needed
} 