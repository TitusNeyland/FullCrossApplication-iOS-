import Foundation

class BibleRepository {
    private let baseURL = "https://api.scripture.api.bible/"
    private let apiKey = "7b7279c82199c911590c615bd99cb895"
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "api-key": apiKey,
            "Content-Type": "application/json"
        ]
        
        self.session = URLSession(configuration: configuration)
    }
    
    func getBibles() async throws -> [Bible] {
        let url = URL(string: baseURL + "v1/bibles")!
        let (data, _) = try await performRequest(url: url)
        let response = try JSONDecoder().decode(BiblesResponse.self, from: data)
        return response.data
    }
    
    func getBooks(bibleId: String) async throws -> [Book] {
        let url = URL(string: baseURL + "v1/bibles/\(bibleId)/books")!
        let (data, _) = try await performRequest(url: url)
        let response = try JSONDecoder().decode(BooksResponse.self, from: data)
        return response.data
    }
    
    func getChapter(bibleId: String, chapterId: String) async throws -> Chapter {
        let url = URL(string: baseURL + "v1/bibles/\(bibleId)/chapters/\(chapterId)")!
        let (data, _) = try await performRequest(url: url)
        let response = try JSONDecoder().decode(ChapterResponse.self, from: data)
        return response.data
    }
    
    func getVerse(bibleId: String, verseId: String) async throws -> Verse {
        let url = URL(string: baseURL + "v1/bibles/\(bibleId)/verses/\(verseId)")!
        let (data, _) = try await performRequest(url: url)
        let response = try JSONDecoder().decode(VerseResponse.self, from: data)
        return response.data
    }
    
    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        return try await session.data(for: request)
    }
}

// MARK: - Errors
enum BibleRepositoryError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
} 