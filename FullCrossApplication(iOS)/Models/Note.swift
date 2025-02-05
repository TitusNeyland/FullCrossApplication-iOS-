import Foundation

struct Note: Identifiable {
    let id: String
    let date: Date
    let title: String
    let content: String
    let verseReference: String?
    let type: NoteType
    let userId: String
    
    init(
        id: String = UUID().uuidString,
        date: Date,
        title: String,
        content: String,
        verseReference: String?,
        type: NoteType,
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

enum NoteType: String {
    case verse = "VERSE"
    case sermon = "SERMON"
    case general = "GENERAL"
} 