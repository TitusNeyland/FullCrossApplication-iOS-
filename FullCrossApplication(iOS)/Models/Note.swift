import Foundation

public struct Note: Identifiable {
    public let id: Int64
    public let date: Date
    public let title: String
    public let content: String
    public let verseReference: String?
    public let type: NoteType
    public let userId: String
    
    public init(id: Int64, date: Date, title: String, content: String, verseReference: String?, type: NoteType, userId: String) {
        self.id = id
        self.date = date
        self.title = title
        self.content = content
        self.verseReference = verseReference
        self.type = type
        self.userId = userId
    }
}

public enum NoteType: String, Codable {
    case verse = "VERSE"
    case sermon = "SERMON"
    case general = "GENERAL"
} 