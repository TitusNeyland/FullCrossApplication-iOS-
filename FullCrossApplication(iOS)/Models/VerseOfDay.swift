import Foundation

struct VerseOfDay: Identifiable, Codable {
    let id: String
    let text: String
    let reference: String
    let date: Date
    
    init(
        id: String = UUID().uuidString,
        text: String,
        reference: String,
        date: Date
    ) {
        self.id = id
        self.text = text
        self.reference = reference
        self.date = date
    }
}

// MARK: - Equatable
extension VerseOfDay: Equatable {
    static func == (lhs: VerseOfDay, rhs: VerseOfDay) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension VerseOfDay: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 