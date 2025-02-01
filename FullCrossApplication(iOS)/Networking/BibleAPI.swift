import Foundation

// MARK: - API Protocol
protocol BibleAPI {
    func getBibles() async throws -> BiblesResponse
    func getBooks(bibleId: String) async throws -> BooksResponse
    func getChapter(bibleId: String, chapterId: String) async throws -> ChapterResponse
    func getVerse(bibleId: String, verseId: String) async throws -> VerseResponse
}

// MARK: - API Implementation
class BibleAPIImpl: BibleAPI {
    private let baseURL = "https://api.scripture.api.bible/v1"
    private let apiKey: String
    private let session: URLSession
    
    init(apiKey: String) {
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "api-key": apiKey,
            "Content-Type": "application/json"
        ]
        self.session = URLSession(configuration: config)
    }
    
    func getBibles() async throws -> BiblesResponse {
        try await performRequest(endpoint: "/bibles")
    }
    
    func getBooks(bibleId: String) async throws -> BooksResponse {
        try await performRequest(endpoint: "/bibles/\(bibleId)/books?include-chapters=true")
    }
    
    func getChapter(bibleId: String, chapterId: String) async throws -> ChapterResponse {
        try await performRequest(endpoint: "/bibles/\(bibleId)/chapters/\(chapterId)")
    }
    
    func getVerse(bibleId: String, verseId: String) async throws -> VerseResponse {
        try await performRequest(endpoint: "/bibles/\(bibleId)/verses/\(verseId)")
    }
    
    private func performRequest<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw BibleAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BibleAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BibleAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // Print the response data for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw BibleAPIError.decodingError(error)
        }
    }
}

// MARK: - Errors
enum BibleAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
} 