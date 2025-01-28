import Foundation

struct Contact: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let phoneNumber: String?
    let email: String?
    let isAppUser: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        isAppUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.isAppUser = isAppUser
    }
}

// MARK: - Sample Data
extension Contact {
    static let sample = Contact(
        name: "John Doe",
        phoneNumber: "+1 (555) 123-4567",
        email: "john.doe@example.com",
        isAppUser: true
    )
    
    static let samples = [
        sample,
        Contact(
            name: "Jane Smith",
            phoneNumber: "+1 (555) 987-6543",
            email: "jane.smith@example.com",
            isAppUser: false
        ),
        Contact(
            name: "Bob Wilson",
            phoneNumber: "+1 (555) 246-8135",
            isAppUser: true
        )
    ]
} 