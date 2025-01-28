import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: Int64
    let date: Date
    let title: String
    let content: String
    let verseReference: String?
    let type: NoteType
    let userId: String
    
    init(
        id: Int64 = 0,
        date: Date = Date(),
        title: String,
        content: String,
        verseReference: String? = nil,
        type: NoteType = .general,
        userId: String
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.content = content
        self.verseReference = verseReference
        self.type = type
        self.userId = userId
    }
}

enum NoteType: String, Codable, CaseIterable {
    case verse = "VERSE"
    case sermon = "SERMON"
    case general = "GENERAL"
    
    var displayName: String {
        switch self {
        case .verse:
            return "Verse Note"
        case .sermon:
            return "Sermon Note"
        case .general:
            return "General Note"
        }
    }
    
    var iconName: String {
        switch self {
        case .verse:
            return "book.fill"
        case .sermon:
            return "mic.fill"
        case .general:
            return "note.text"
        }
    }
}

// MARK: - Sample Data
extension Note {
    static let sample = Note(
        id: 1,
        date: Date(),
        title: "Sunday Sermon Notes",
        content: "Key points from today's message about grace and forgiveness...",
        type: .sermon,
        userId: "user123"
    )
    
    static let samples = [
        sample,
        Note(
            id: 2,
            date: Date().addingTimeInterval(-86400), // Yesterday
            title: "John 3:16 Reflection",
            content: "Reflecting on God's love for the world...",
            verseReference: "John 3:16",
            type: .verse,
            userId: "user123"
        ),
        Note(
            id: 3,
            date: Date().addingTimeInterval(-172800), // 2 days ago
            title: "Prayer List",
            content: "People to pray for this week...",
            type: .general,
            userId: "user123"
        )
    ]
}

// MARK: - Date Formatting
extension Note {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
} 