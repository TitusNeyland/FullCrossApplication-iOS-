import Foundation
import Combine
import FirebaseAuth

@MainActor
class BibleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var bibles: [Bible] = []
    @Published private(set) var books: [Book] = []
    @Published private(set) var currentChapter: Chapter?
    @Published private(set) var currentChapterNumber: Int?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var selectedBible: Bible?
    @Published private(set) var selectedBook: Book?
    @Published private(set) var selectedVerse: String?
    @Published private(set) var verseOfDay: VerseOfDay?
    @Published private(set) var isLoadingVerse = false
    @Published private(set) var verseError: String?
    
    // MARK: - Private Properties
    private let repository: BibleAPI
    private let noteRepository: NoteRepository
    private let defaultBibleId = "de4e12af7f28f599-02" // ESV
    private var cancellables = Set<AnyCancellable>()
    
    private let verseIds = [
        "JHN.3.16", "PHP.4.13", "PRO.3.5", "PSA.23.1",
        "ROM.8.28", "JER.29.11", "ISA.41.10", "MAT.11.28",
        "JOS.1.9", "HEB.11.1"
    ]
    
    private let biblicalBookOrder = [
        // Old Testament
        "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA",
        "1KI", "2KI", "1CH", "2CH", "EZR", "NEH", "EST", "JOB", "PSA", "PRO",
        "ECC", "SNG", "ISA", "JER", "LAM", "EZK", "DAN", "HOS", "JOL", "AMO",
        "OBA", "JON", "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL",
        // New Testament
        "MAT", "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO", "GAL", "EPH",
        "PHP", "COL", "1TH", "2TH", "1TI", "2TI", "TIT", "PHM", "HEB", "JAS",
        "1PE", "2PE", "1JN", "2JN", "3JN", "JUD", "REV"
    ]
    
    // MARK: - Initialization
    nonisolated init(repository: BibleAPI, noteRepository: NoteRepository) {
        self.repository = repository
        self.noteRepository = noteRepository
        
        // Move async work to a separate method
        Task { @MainActor in
            await self.initialize()
        }
    }
    
    private func initialize() async {
        await loadBibles()
        await fetchVerseOfDay()
    }
    
    // MARK: - Public Methods
    func loadBibles() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await repository.getBibles()
            bibles = response.data.filter { $0.language.id == "eng" } // Optional: filter for English bibles only
        } catch {
            self.error = "Failed to load Bibles: \(error.localizedDescription)"
            print("Error loading Bibles: \(error)")
        }
        
        isLoading = false
    }
    
    func loadBooks(bibleId: String) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await repository.getBooks(bibleId: bibleId)
            // Sort books according to biblical order
            books = response.data.sorted { book1, book2 in
                let index1 = biblicalBookOrder.firstIndex(of: book1.id.prefix(3).uppercased()) ?? Int.max
                let index2 = biblicalBookOrder.firstIndex(of: book2.id.prefix(3).uppercased()) ?? Int.max
                return index1 < index2
            }
        } catch {
            self.error = "Failed to load books: \(error.localizedDescription)"
            print("Error loading books: \(error)")
            print("Detailed error: \(error)")
        }
        
        isLoading = false
    }
    
    func loadChapter(bibleId: String, chapterId: String) async {
        isLoading = true
        error = nil
        
        do {
            let response = try await repository.getChapter(bibleId: bibleId, chapterId: chapterId)
            currentChapter = response.data
            currentChapterNumber = Int(response.data.number)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadNextChapter(bibleId: String) async {
        guard let currentNumber = currentChapterNumber,
              let bookId = selectedBook?.id else { return }
        
        let nextChapterId = "\(bookId).\(currentNumber + 1)"
        await loadChapter(bibleId: bibleId, chapterId: nextChapterId)
    }
    
    func loadPreviousChapter(bibleId: String) async {
        guard let currentNumber = currentChapterNumber,
              currentNumber > 1,
              let bookId = selectedBook?.id else { return }
        
        let previousChapterId = "\(bookId).\(currentNumber - 1)"
        await loadChapter(bibleId: bibleId, chapterId: previousChapterId)
    }
    
    func clearChapter() {
        currentChapter = nil
        currentChapterNumber = nil
        selectedBook = nil
    }
    
    func setSelectedBible(_ bible: Bible?) {
        selectedBible = bible
        if let bible = bible {
            Task {
                await loadBooks(bibleId: bible.id)
            }
        } else {
            books = []
        }
    }
    
    func setSelectedBook(_ book: Book?) {
        selectedBook = book
    }
    
    func setSelectedVerse(_ verse: String) {
        selectedVerse = verse
    }
    
    func addVerseNote(title: String, content: String, verseReference: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let note = Note(
            date: Date(),
            title: title,
            content: content,
            verseReference: verseReference,
            type: .verse,
            userId: userId
        )
        
        do {
            try await noteRepository.insertNote(note)
            // Post a notification to refresh notes
            NotificationCenter.default.post(name: .noteAdded, object: nil)
            selectedVerse = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshVerseOfDay() {
        Task {
            await fetchVerseOfDay()
        }
    }
    
    // MARK: - Private Methods
    private func fetchVerseOfDay() async {
        isLoadingVerse = true
        verseError = nil
        
        do {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            let verseId = verseIds[dayOfYear % verseIds.count]
            
            let response = try await repository.getVerse(bibleId: defaultBibleId, verseId: verseId)
            let verseData = response.data
            
            // Remove HTML tags if present
            let cleanContent = verseData.content.replacingOccurrences(
                of: "<[^>]+>",
                with: "",
                options: .regularExpression
            )
            
            verseOfDay = VerseOfDay(
                text: cleanContent,
                reference: verseData.reference,
                date: Date()
            )
        } catch {
            verseError = error.localizedDescription
        }
        
        isLoadingVerse = false
    }
} 