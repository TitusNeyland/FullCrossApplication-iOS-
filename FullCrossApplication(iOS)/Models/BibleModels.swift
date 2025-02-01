import Foundation

// MARK: - Response Models
struct BiblesResponse: Codable {
    let data: [Bible]
}

struct BooksResponse: Codable {
    let data: [Book]
}

struct ChapterResponse: Codable {
    let data: Chapter
}

struct VerseResponse: Codable {
    let data: Verse
}

// MARK: - Data Models
struct Bible: Codable, Identifiable {
    let id: String
    let dblId: String?
    let abbreviation: String?
    let abbreviationLocal: String?
    let name: String
    let nameLocal: String?
    let description: String?
    let descriptionLocal: String?
    let language: Language
    
    enum CodingKeys: String, CodingKey {
        case id
        case dblId
        case abbreviation
        case abbreviationLocal
        case name
        case nameLocal
        case description
        case descriptionLocal
        case language
    }
}

struct Language: Codable {
    let id: String
    let name: String
    let nameLocal: String?
    let script: String?
    let scriptDirection: String?
}

struct Book: Codable, Identifiable {
    let id: String
    let bibleId: String
    let abbreviation: String?
    let name: String
    let nameLong: String?
    
    // Optional fields that might be present in the API response
    let chapters: [ChapterSummary]?
    let testament: String?
}

struct ChapterSummary: Codable, Identifiable {
    let id: String
    let bibleId: String
    let number: String
    let bookId: String
    let reference: String?
}

struct Chapter: Codable, Identifiable {
    let id: String
    let number: String
    let reference: String
    let content: String
    let verseCount: Int
    let verses: [VerseSummary]?
}

struct VerseSummary: Codable, Identifiable {
    let id: String
    let reference: String
}

struct Verse: Codable, Identifiable {
    let id: String
    let reference: String
    let content: String
} 