import Foundation

struct Contact: Identifiable {
    let id = UUID()
    let name: String
    let phoneNumber: String?
    let isAppUser: Bool
} 