import Foundation
import Contacts
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class ContactsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var contacts: [Contact] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var searchQuery = ""
    @Published private(set) var searchResults: [UserProfile] = []
    @Published private(set) var isSearching = false
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var pendingFriendRequests: [UserProfile] = []
    
    // MARK: - Private Properties
    private let authViewModel: AuthViewModel
    private let contactsRepository: ContactsRepository
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    // MARK: - Initialization
    init(authViewModel: AuthViewModel, contactsRepository: ContactsRepository = ContactsRepositoryImpl()) {
        self.authViewModel = authViewModel
        self.contactsRepository = contactsRepository
        Task {
            await fetchFriends()
            setupPendingFriendRequestsListener()
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    // MARK: - Public Methods
    func syncContacts() async {
        isLoading = true
        error = nil
        
        do {
            contacts = try await contactsRepository.getContacts()
        } catch {
            self.error = "Failed to sync contacts: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func searchUsers(_ query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        
        searchQuery = query
        isSearching = true
        
        do {
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
            }
            
            let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let snapshot = try await db.collection("users").getDocuments()
            
            searchResults = snapshot.documents.compactMap { doc in
                guard doc.documentID != currentUserId else { return nil }
                
                let firstName = (doc["firstName"] as? String ?? "").lowercased()
                let lastName = (doc["lastName"] as? String ?? "").lowercased()
                let phone = (doc["phoneNumber"] as? String ?? "").replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                
                if firstName.contains(cleanQuery) || lastName.contains(cleanQuery) || phone.contains(cleanQuery) {
                    return UserProfile(
                        id: doc.documentID,
                        firstName: doc["firstName"] as? String ?? "",
                        lastName: doc["lastName"] as? String ?? "",
                        phoneNumber: phone,
                        friendshipStatus: .none
                    )
                }
                return nil
            }
        } catch {
            self.error = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
    
    func removeFriend(_ friendId: String) async {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
            }
            
            let batch = db.batch()
            
            // Delete friendship documents for both users
            let currentUserFriendshipRef = db.collection("users")
                .document(currentUser.uid)
                .collection("friendships")
                .document(friendId)
            
            let otherUserFriendshipRef = db.collection("users")
                .document(friendId)
                .collection("friendships")
                .document(currentUser.uid)
            
            batch.deleteDocument(currentUserFriendshipRef)
            batch.deleteDocument(otherUserFriendshipRef)
            
            try await batch.commit()
            await fetchFriends()
            await authViewModel.fetchFriendsCount()
            
        } catch {
            self.error = "Failed to remove friend: \(error.localizedDescription)"
        }
    }
    
    func acceptFriendRequest(_ fromUserId: String) async {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
            }
            
            let timestamp = Date()
            let batch = db.batch()
            
            // Update friendship status for both users
            let currentUserFriendshipRef = db.collection("users")
                .document(currentUser.uid)
                .collection("friendships")
                .document(fromUserId)
            
            batch.setData([
                "status": "accepted",
                "timestamp": timestamp
            ], forDocument: currentUserFriendshipRef)
            
            let otherUserFriendshipRef = db.collection("users")
                .document(fromUserId)
                .collection("friendships")
                .document(currentUser.uid)
            
            batch.setData([
                "status": "accepted",
                "timestamp": timestamp
            ], forDocument: otherUserFriendshipRef)
            
            try await batch.commit()
            await fetchFriends()
            
            // Add this line to update friends count
            await authViewModel.fetchFriendsCount()
            
        } catch {
            self.error = "Failed to accept friend request: \(error.localizedDescription)"
        }
    }
    
    func declineFriendRequest(_ fromUserId: String) async {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
            }
            
            let batch = db.batch()
            
            // Delete friendship documents for both users
            let currentUserFriendshipRef = db.collection("users")
                .document(currentUser.uid)
                .collection("friendships")
                .document(fromUserId)
            
            batch.deleteDocument(currentUserFriendshipRef)
            
            let otherUserFriendshipRef = db.collection("users")
                .document(fromUserId)
                .collection("friendships")
                .document(currentUser.uid)
            
            batch.deleteDocument(otherUserFriendshipRef)
            
            try await batch.commit()
            await fetchFriends()
            
        } catch {
            self.error = "Failed to decline friend request: \(error.localizedDescription)"
        }
    }
    
    func sendFriendRequest(toUserId: String, toUserName: String) async {
        do {
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                print("❌ Friend Request Failed: User not logged in")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
            }
            
            // Prevent sending friend request to self
            if currentUserId == toUserId {
                print("❌ Friend Request Failed: Cannot send request to self")
                self.error = "You cannot send a friend request to yourself"
                return
            }
            
            print("📤 Initiating friend request to: \(toUserName)")
            let timestamp = Timestamp(date: Date())
            let batch = db.batch()
            
            // Get current user's name for the notification
            let currentUserDoc = try await db.collection("users")
                .document(currentUserId)
                .getDocument()
            
            let currentUserName = "\(currentUserDoc.get("firstName") as? String ?? "") \(currentUserDoc.get("lastName") as? String ?? "")"
            print("👤 Sender: \(currentUserName)")
            
            // Create friendship document for recipient
            let recipientRef = db.collection("users")
                .document(toUserId)
                .collection("friendships")
                .document(currentUserId)
            
            batch.setData([
                "status": "pending",
                "timestamp": timestamp,
                "type": "received",
                "fromUserName": currentUserName
            ], forDocument: recipientRef)
            print("📝 Created recipient friendship document")
            
            // Create friendship document for sender
            let senderRef = db.collection("users")
                .document(currentUserId)
                .collection("friendships")
                .document(toUserId)
            
            batch.setData([
                "status": "pending",
                "timestamp": timestamp,
                "type": "sent",
                "toUserName": toUserName
            ], forDocument: senderRef)
            print("📝 Created sender friendship document")
            
            // Create notification for recipient
            let notificationRef = db.collection("users")
                .document(toUserId)
                .collection("notifications")
                .document()
            
            batch.setData([
                "type": "FRIEND_REQUEST",
                "fromUserId": currentUserId,
                "fromUserName": currentUserName,
                "timestamp": timestamp,
                "read": false
            ], forDocument: notificationRef)
            print("🔔 Created notification document")
            
            try await batch.commit()
            print("✅ Friend request successfully sent to \(toUserName)")
            
            // Refresh UI
            if !searchQuery.isEmpty {
                await searchUsers(searchQuery)
            }
        } catch {
            print("❌ Friend Request Failed: \(error.localizedDescription)")
            self.error = "Failed to send friend request: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    private func fetchFriends() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let friendships = try await db.collection("users")
                .document(currentUserId)
                .collection("friendships")
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()
            
            let friendProfiles = try await withThrowingTaskGroup(of: UserProfile?.self) { group in
                for doc in friendships.documents {
                    let friendId = doc.documentID
                    group.addTask {
                        let friendDoc = try await self.db.collection("users")
                            .document(friendId)
                            .getDocument()
                        
                        guard friendDoc.exists else { return nil }
                        
                        return UserProfile(
                            id: friendDoc.documentID,
                            firstName: friendDoc.get("firstName") as? String ?? "",
                            lastName: friendDoc.get("lastName") as? String ?? "",
                            phoneNumber: friendDoc.get("phoneNumber") as? String ?? "",
                            friendshipStatus: .accepted
                        )
                    }
                }
                
                var profiles: [UserProfile] = []
                for try await profile in group {
                    if let profile = profile {
                        profiles.append(profile)
                    }
                }
                return profiles
            }
            
            self.friends = friendProfiles
            
        } catch {
            self.error = "Failed to fetch friends: \(error.localizedDescription)"
        }
    }
    
    private func setupPendingFriendRequestsListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Listen for pending friend requests
        listenerRegistration = db.collection("users")
            .document(currentUserId)
            .collection("friendships")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = "Error fetching friend requests: \(error.localizedDescription)"
                    return
                }
                
                Task {
                    do {
                        let pendingRequests = try await withThrowingTaskGroup(of: UserProfile?.self) { group in
                            for doc in snapshot?.documents ?? [] {
                                let friendId = doc.documentID
                                group.addTask {
                                    let friendDoc = try await self.db.collection("users")
                                        .document(friendId)
                                        .getDocument()
                                    
                                    guard friendDoc.exists else { return nil }
                                    
                                    return UserProfile(
                                        id: friendDoc.documentID,
                                        firstName: friendDoc.get("firstName") as? String ?? "",
                                        lastName: friendDoc.get("lastName") as? String ?? "",
                                        phoneNumber: friendDoc.get("phoneNumber") as? String ?? "",
                                        friendshipStatus: .pending
                                    )
                                }
                            }
                            
                            var profiles: [UserProfile] = []
                            for try await profile in group {
                                if let profile = profile {
                                    profiles.append(profile)
                                }
                            }
                            return profiles
                        }
                        
                        self.pendingFriendRequests = pendingRequests
                    } catch {
                        self.error = "Failed to process friend requests: \(error.localizedDescription)"
                    }
                }
            }
    }
} 