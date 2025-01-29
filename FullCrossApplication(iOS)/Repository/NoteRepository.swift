import Foundation
import Combine
import FirebaseFirestore

protocol NoteRepository {
    func getNotesForDate(date: Date, userId: String) -> AnyPublisher<[Note], Error>
    func getAllNotes(userId: String) -> AnyPublisher<[Note], Error>
    func insertNote(_ note: Note) async throws
    func updateNote(_ note: Note) async throws
    func deleteNote(_ note: Note) async throws
    func getDatesWithNotes(userId: String) -> AnyPublisher<[Date], Error>
}

// Firestore implementation
class FirestoreNoteRepository: NoteRepository {
    private let db = Firestore.firestore()
    
    func getNotesForDate(date: Date, userId: String) -> AnyPublisher<[Note], Error> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        print("Fetching notes between \(startOfDay) and \(endOfDay)")
        
        return db.collection("notes")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .order(by: "date", descending: true)
            .snapshotPublisher()
            .map { snapshot in
                print("Found \(snapshot.documents.count) documents")
                return snapshot.documents.compactMap { document -> Note? in
                    print("Processing document ID: \(document.documentID)")
                    
                    guard let date = document.get("date") as? Timestamp,
                          let title = document.get("title") as? String,
                          let content = document.get("content") as? String,
                          let typeRaw = document.get("type") as? String,
                          let type = NoteType(rawValue: typeRaw) else {
                        print("Failed to parse document \(document.documentID)")
                        return nil
                    }
                    
                    let note = Note(
                        id: document.documentID,
                        date: date.dateValue(),
                        title: title,
                        content: content,
                        verseReference: document.get("verseReference") as? String,
                        type: type,
                        userId: userId
                    )
                    print("Successfully parsed note: \(note.title)")
                    return note
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getAllNotes(userId: String) -> AnyPublisher<[Note], Error> {
        db.collection("notes")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .snapshotPublisher()
            .map { snapshot in
                snapshot.documents.compactMap { document -> Note? in
                    guard let date = document.get("date") as? Timestamp,
                          let title = document.get("title") as? String,
                          let content = document.get("content") as? String,
                          let typeRaw = document.get("type") as? String,
                          let type = NoteType(rawValue: typeRaw) else {
                        return nil
                    }
                    
                    return Note(
                        id: document.documentID,
                        date: date.dateValue(),
                        title: title,
                        content: content,
                        verseReference: document.get("verseReference") as? String,
                        type: type,
                        userId: userId
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func insertNote(_ note: Note) async throws {
        let docRef = try await db.collection("notes").addDocument(data: [
            "date": Timestamp(date: note.date),
            "title": note.title,
            "content": note.content,
            "verseReference": note.verseReference as Any,
            "type": note.type.rawValue,
            "userId": note.userId
        ])
        
        // Store the document ID directly instead of trying to convert it to Int64
        print("Created note with ID: \(docRef.documentID)")
    }
    
    func updateNote(_ note: Note) async throws {
        try await db.collection("notes")
            .document(note.id)
            .updateData([
                "date": Timestamp(date: note.date),
                "title": note.title,
                "content": note.content,
                "verseReference": note.verseReference as Any,
                "type": note.type.rawValue
            ])
    }
    
    func deleteNote(_ note: Note) async throws {
        try await db.collection("notes")
            .document(note.id)
            .delete()
    }
    
    func getDatesWithNotes(userId: String) -> AnyPublisher<[Date], Error> {
        db.collection("notes")
            .whereField("userId", isEqualTo: userId)
            .snapshotPublisher()
            .map { snapshot in
                let calendar = Calendar.current
                let dates = snapshot.documents.compactMap { document -> Date? in
                    guard let timestamp = document.get("date") as? Timestamp else {
                        return nil
                    }
                    // Normalize to start of day
                    return calendar.startOfDay(for: timestamp.dateValue())
                }
                // Use Set to ensure uniqueness, then convert back to sorted array
                return Array(Set(dates)).sorted(by: >)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Firestore Extensions
private extension Query {
    func snapshotPublisher() -> AnyPublisher<QuerySnapshot, Error> {
        FirestoreQueryPublisher(query: self).eraseToAnyPublisher()
    }
}

private struct FirestoreQueryPublisher: Publisher {
    typealias Output = QuerySnapshot
    typealias Failure = Error
    
    private let query: Query
    
    init(query: Query) {
        self.query = query
    }
    
    func receive<S>(subscriber: S) where S: Subscriber,
                                       S.Failure == Failure,
                                       S.Input == Output {
        let subscription = FirestoreQuerySubscription(
            subscriber: subscriber,
            query: query
        )
        subscriber.receive(subscription: subscription)
    }
}

private final class FirestoreQuerySubscription<S: Subscriber>: Subscription where S.Input == QuerySnapshot,
                                                                                S.Failure == Error {
    private var subscriber: S?
    private var listener: ListenerRegistration?
    
    init(subscriber: S, query: Query) {
        self.subscriber = subscriber
        listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                subscriber.receive(completion: .failure(error))
                return
            }
            guard let snapshot = snapshot else { return }
            _ = subscriber.receive(snapshot)
        }
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        subscriber = nil
        listener?.remove()
        listener = nil
    }
} 