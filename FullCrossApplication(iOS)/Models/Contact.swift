import Foundation

struct Contact: Identifiable {
    let id: String
    let name: String
    let phoneNumber: String?
    var isAppUser: Bool
    var userId: String?
} 