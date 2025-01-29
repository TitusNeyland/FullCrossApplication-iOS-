import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class NotesViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var notes: [Note] = []
    @Published var datesWithNotes: Set<Date> = []
    @Published var discussions: [Discussion] = []
    @Published var currentUserName: String?
    
    private let noteRepository: NoteRepository
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private var cancellables = Set<AnyCancellable>()
    private var discussionsListener: ListenerRegistration?
    
    init(noteRepository: NoteRepository = FirestoreNoteRepository()) {
        self.noteRepository = noteRepository
        setupAuthStateListener()
        if auth.currentUser != nil {
            refreshAllData()
        }
    }
    
    deinit {
        discussionsListener?.remove()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.refreshAllData()
            } else {
                self?.clearAllData()
            }
        }
    }
    
    private func clearAllData() {
        notes = []
        datesWithNotes = []
        currentUserName = nil
        selectedDate = Date()
    }
    
    private func refreshAllData() {
        loadNotesForDate(Date())
        loadDatesWithNotes()
        loadDiscussions()
        loadCurrentUserName()
    }
    
    private func getCurrentUserId() throws -> String {
        guard let userId = auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        return userId
    }
    
    private func loadCurrentUserName() {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                let firstName = document.get("firstName") as? String ?? ""
                let lastName = document.get("lastName") as? String ?? ""
                self?.currentUserName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            }
        }
    }
    
    func setSelectedDate(_ date: Date) {
        selectedDate = date
        loadNotesForDate(date)
    }
    
    private func loadNotesForDate(_ date: Date) {
        do {
            let userId = try getCurrentUserId()
            noteRepository.getNotesForDate(date: date, userId: userId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] notes in
                        self?.notes = notes
                    }
                )
                .store(in: &cancellables)
        } catch {
            notes = []
        }
    }
    
    func addNote(title: String, content: String, verseReference: String?, type: NoteType) {
        Task {
            do {
                let userId = try getCurrentUserId()
                let note = Note(
                    id: 0, // Firestore will generate this
                    date: Date(),
                    title: title,
                    content: content,
                    verseReference: verseReference,
                    type: type,
                    userId: userId
                )
                try await noteRepository.insertNote(note)
                await MainActor.run {
                    setSelectedDate(Date())
                }
            } catch {
                print("Error adding note: \(error)")
            }
        }
    }
    
    func deleteNote(_ note: Note) {
        Task {
            do {
                let userId = try getCurrentUserId()
                if note.userId == userId {
                    try await noteRepository.deleteNote(note)
                }
            } catch {
                print("Error deleting note: \(error)")
            }
        }
    }
    
    private func loadDatesWithNotes() {
        do {
            let userId = try getCurrentUserId()
            noteRepository.getDatesWithNotes(userId: userId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] dates in
                        self?.datesWithNotes = Set(dates)
                    }
                )
                .store(in: &cancellables)
        } catch {
            datesWithNotes = []
        }
    }
    
    private func loadDiscussions() {
        discussionsListener?.remove()
        
        discussionsListener = db.collection("discussions")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching discussions: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Implementation for discussions will be added in the next part
                // This will include mapping Firestore documents to Discussion objects
                // and setting up nested listeners for comments
            }
    }
    
    func addDiscussion(title: String, content: String) {
        guard let currentUser = auth.currentUser else { return }
        
        Task {
            do {
                let userDoc = try await db.collection("users")
                    .document(currentUser.uid)
                    .getDocument()
                
                let firstName = userDoc.get("firstName") as? String ?? ""
                let lastName = userDoc.get("lastName") as? String ?? ""
                let authorName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                
                let discussionData: [String: Any] = [
                    "title": title,
                    "content": content,
                    "authorId": currentUser.uid,
                    "authorName": authorName,
                    "timestamp": Date().timeIntervalSince1970,
                    "likes": 0,
                    "commentCount": 0,
                    "tags": [],
                    "likedByUsers": []
                ]
                
                try await db.collection("discussions").addDocument(data: discussionData)
            } catch {
                print("Error adding discussion: \(error)")
            }
        }
    }
    
    func likeDiscussion(_ discussionId: String) {
        guard let currentUser = auth.currentUser else { return }
        
        let discussionRef = db.collection("discussions").document(discussionId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let discussionDoc: DocumentSnapshot
            do {
                discussionDoc = try transaction.getDocument(discussionRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let likedByUsers = discussionDoc.get("likedByUsers") as? [String] ?? []
            let currentLikes = discussionDoc.get("likes") as? Int ?? 0
            
            if likedByUsers.contains(currentUser.uid) {
                // Unlike
                transaction.updateData([
                    "likedByUsers": FieldValue.arrayRemove([currentUser.uid]),
                    "likes": currentLikes - 1
                ], forDocument: discussionRef)
            } else {
                // Like
                transaction.updateData([
                    "likedByUsers": FieldValue.arrayUnion([currentUser.uid]),
                    "likes": currentLikes + 1
                ], forDocument: discussionRef)
            }
            
            return nil
        }) { _, error in
            if let error = error {
                print("Error updating discussion likes: \(error)")
            }
        }
    }
    
    func addComment(discussionId: String, content: String, parentCommentId: String? = nil, replyToAuthorName: String? = nil) {
        guard let currentUser = auth.currentUser else { return }
        
        Task {
            do {
                let userDoc = try await db.collection("users")
                    .document(currentUser.uid)
                    .getDocument()
                
                let firstName = userDoc.get("firstName") as? String ?? ""
                let lastName = userDoc.get("lastName") as? String ?? ""
                let authorName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                
                let commentData: [String: Any] = [
                    "content": content,
                    "authorId": currentUser.uid,
                    "authorName": authorName,
                    "timestamp": Date().timeIntervalSince1970,
                    "likes": 0,
                    "parentCommentId": parentCommentId as Any,
                    "replyToAuthorName": replyToAuthorName as Any,
                    "replyCount": 0,
                    "isReply": parentCommentId != nil
                ]
                
                let batch = db.batch()
                
                // Add the comment
                let commentRef = db.collection("discussions")
                    .document(discussionId)
                    .collection("comments")
                    .document()
                
                batch.setData(commentData, forDocument: commentRef)
                
                // Update discussion comment count
                let discussionRef = db.collection("discussions").document(discussionId)
                batch.updateData([
                    "commentCount": FieldValue.increment(Int64(1))
                ], forDocument: discussionRef)
                
                // If this is a reply, update parent comment's reply count
                if let parentId = parentCommentId {
                    let parentCommentRef = db.collection("discussions")
                        .document(discussionId)
                        .collection("comments")
                        .document(parentId)
                    
                    batch.updateData([
                        "replyCount": FieldValue.increment(Int64(1))
                    ], forDocument: parentCommentRef)
                }
                
                try await batch.commit()
            } catch {
                print("Error adding comment: \(error)")
            }
        }
    }
    
    func deleteComment(discussionId: String, commentId: String) {
        guard let currentUser = auth.currentUser else { return }
        
        Task {
            do {
                let commentRef = db.collection("discussions")
                    .document(discussionId)
                    .collection("comments")
                    .document(commentId)
                
                let commentDoc = try await commentRef.getDocument()
                guard commentDoc.get("authorId") as? String == currentUser.uid else { return }
                
                let batch = db.batch()
                
                // Delete the comment
                batch.deleteDocument(commentRef)
                
                // Update discussion comment count
                let discussionRef = db.collection("discussions").document(discussionId)
                batch.updateData([
                    "commentCount": FieldValue.increment(Int64(-1))
                ], forDocument: discussionRef)
                
                // If this was a reply, update parent comment's reply count
                if let parentId = commentDoc.get("parentCommentId") as? String {
                    let parentRef = db.collection("discussions")
                        .document(discussionId)
                        .collection("comments")
                        .document(parentId)
                    
                    batch.updateData([
                        "replyCount": FieldValue.increment(Int64(-1))
                    ], forDocument: parentRef)
                }
                
                try await batch.commit()
            } catch {
                print("Error deleting comment: \(error)")
            }
        }
    }
    
    func deleteDiscussion(_ discussionId: String) {
        guard let currentUser = auth.currentUser else { return }
        
        Task {
            do {
                let discussionRef = db.collection("discussions").document(discussionId)
                let discussionDoc = try await discussionRef.getDocument()
                
                guard discussionDoc.get("authorId") as? String == currentUser.uid else { return }
                
                // Delete all comments first
                let commentsSnapshot = try await discussionRef.collection("comments").getDocuments()
                
                let batch = db.batch()
                commentsSnapshot.documents.forEach { commentDoc in
                    batch.deleteDocument(commentDoc.reference)
                }
                
                // Delete the discussion
                batch.deleteDocument(discussionRef)
                
                try await batch.commit()
            } catch {
                print("Error deleting discussion: \(error)")
            }
        }
    }
} 