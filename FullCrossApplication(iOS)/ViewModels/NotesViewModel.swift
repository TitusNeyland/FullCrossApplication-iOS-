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
    private let calendar = Calendar.current
    
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
                    // Update UI state immediately
                    await MainActor.run {
                        self.notes = self.notes.filter { $0.id != note.id }
                        // Also update dates with notes if needed
                        if !self.notes.contains(where: { calendar.startOfDay(for: $0.date) == calendar.startOfDay(for: note.date) }) {
                            self.datesWithNotes.remove(calendar.startOfDay(for: note.date))
                        }
                    }
                    // Then delete from Firestore
                    try await noteRepository.deleteNote(note)
                }
            } catch {
                print("Error deleting note: \(error)")
                // Revert the UI state if deletion fails
                await MainActor.run {
                    loadNotesForDate(selectedDate)
                }
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
        
        print("Setting up discussions listener...")
        
        discussionsListener = db.collection("discussions")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching discussions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in discussions collection")
                    return
                }
                
                print("Found \(documents.count) discussions")
                
                let discussions = documents.compactMap { document -> Discussion? in
                    do {
                        let data = document.data()
                        let discussion = Discussion(
                            id: document.documentID,
                            title: data["title"] as? String ?? "",
                            content: data["content"] as? String ?? "",
                            authorId: data["authorId"] as? String ?? "",
                            authorName: data["authorName"] as? String ?? "",
                            timestamp: data["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970,
                            likes: data["likes"] as? Int ?? 0,
                            commentCount: data["commentCount"] as? Int ?? 0,
                            tags: data["tags"] as? [String] ?? [],
                            comments: [],
                            likedByUsers: Set(data["likedByUsers"] as? [String] ?? [])
                        )
                        
                        // Set up comments listener for this discussion
                        self.setupCommentsListener(for: discussion)
                        
                        print("Successfully parsed discussion: \(discussion.title)")
                        return discussion
                    } catch {
                        print("Error parsing discussion document: \(error)")
                        return nil
                    }
                }
                
                print("Processed \(discussions.count) valid discussions")
                
                DispatchQueue.main.async {
                    self.discussions = discussions
                    print("Updated discussions array, now contains \(self.discussions.count) items")
                }
            }
    }
    
    private func setupCommentsListener(for discussion: Discussion) {
        db.collection("discussions")
            .document(discussion.id)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching comments: \(error.localizedDescription)")
                    return
                }
                
                let comments = snapshot?.documents.compactMap { document -> Comment? in
                    let data = document.data()
                    return Comment(
                        id: document.documentID,
                        discussionId: discussion.id,
                        content: data["content"] as? String ?? "",
                        authorId: data["authorId"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "",
                        timestamp: data["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970,
                        parentCommentId: data["parentCommentId"] as? String,
                        replyToAuthorName: data["replyToAuthorName"] as? String,
                        replyCount: data["replyCount"] as? Int ?? 0,
                        isReply: data["isReply"] as? Bool ?? false
                    )
                } ?? []
                
                // Group comments by parent ID to organize replies
                let commentMap = Dictionary(grouping: comments) { $0.parentCommentId }
                
                // Get top-level comments (no parent)
                let topLevelComments = commentMap[nil] ?? []
                
                // Create a list with all comments in the correct order
                let orderedComments = topLevelComments.flatMap { parentComment in
                    [parentComment] + (commentMap[parentComment.id] ?? [])
                }
                
                DispatchQueue.main.async {
                    // Update the discussion's comments
                    if let index = self.discussions.firstIndex(where: { $0.id == discussion.id }) {
                        self.discussions[index].comments = orderedComments
                    }
                }
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
                    "parentCommentId": parentCommentId as Any,
                    "replyToAuthorName": replyToAuthorName as Any,
                    "isReply": parentCommentId != nil
                ]
                
                let discussionRef = db.collection("discussions").document(discussionId)
                let commentRef = try await discussionRef.collection("comments").addDocument(data: commentData)
                
                try await discussionRef.updateData([
                    "commentCount": FieldValue.increment(Int64(1))
                ])
                
                if let parentCommentId = parentCommentId {
                    try await discussionRef.collection("comments")
                        .document(parentCommentId)
                        .updateData([
                            "replyCount": FieldValue.increment(Int64(1))
                        ])
                }
            } catch {
                print("Error adding comment: \(error)")
            }
        }
    }
    
    func deleteComment(discussionId: String, commentId: String) {
        Task {
            do {
                let discussionRef = db.collection("discussions").document(discussionId)
                try await discussionRef.collection("comments").document(commentId).delete()
                try await discussionRef.updateData([
                    "commentCount": FieldValue.increment(Int64(-1))
                ])
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