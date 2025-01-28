import Foundation
import Contacts
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ContactsViewModel: ObservableObject {
    @Published private(set) var contacts: [Contact] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var searchResults: [UserProfile] = []
    @Published private(set) var isSearching = false
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var pendingFriendRequests: [UserProfile] = []
    
    private let authViewModel: AuthViewModel
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        Task {
            await fetchFriends()
            setupPendingFriendRequestsListener()
        }
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    private func fetchFriends() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let friendships = try await db.collection("users")
                .document(currentUserId)
                .collection("friendships")
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()
            
            let friendIds = friendships.documents.map { $0.documentID }
            
            let friendProfiles = try await withThrowingTaskGroup(of: UserProfile?.self) { group in
                for friendId in friendIds {
                    group.addTask {
                        let doc = try await self.db.collection("users")
                            .document(friendId)
                            .getDocument()
                        
                        guard doc.exists else { return nil }
                        
                        return UserProfile(
                            id: doc.documentID,
                            firstName: doc.get("firstName") as? String ?? "",
                            lastName: doc.get("lastName") as? String ?? "",
                            phoneNumber: doc.get("phoneNumber") as? String ?? "",
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
    
    func syncContacts() async {
        isLoading = true
        error = nil
        
        let store = CNContactStore()
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]
        
        do {
            let containerId = store.defaultContainerIdentifier()
            let predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerId)
            
            let cnContacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            
            contacts = cnContacts.map { cnContact in
                Contact(
                    name: "\(cnContact.givenName) \(cnContact.familyName)".trimmingCharacters(in: .whitespaces),
                    phoneNumber: cnContact.phoneNumbers.first?.value.stringValue,
                    isAppUser: false  // TODO: Check against Firebase
                )
            }
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
                        phoneNumber: phone
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
        searchResults = []
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
            guard let currentUser = Auth.auth().currentUser else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])
            }
            
            guard currentUser.uid != toUserId else {
                error = "You cannot send a friend request to yourself"
                return
            }
            
            let currentUserDoc = try await db.collection("users")
                .document(currentUser.uid)
                .getDocument()
            
            let currentUserName = "\(currentUserDoc["firstName"] as? String ?? "") \(currentUserDoc["lastName"] as? String ?? "")"
            let timestamp = Date()
            
            let batch = db.batch()
            
            // Create friendship document for recipient
            let recipientFriendshipRef = db.collection("users")
                .document(toUserId)
                .collection("friendships")
                .document(currentUser.uid)
            
            batch.setData([
                "status": "pending",
                "timestamp": timestamp
            ], forDocument: recipientFriendshipRef)
            
            // Create notification for recipient
            let notificationRef = db.collection("users")
                .document(toUserId)
                .collection("notifications")
                .document()
            
            batch.setData([
                "type": NotificationType.friendRequest.rawValue,
                "fromUserId": currentUser.uid,
                "fromUserName": currentUserName,
                "timestamp": timestamp,
                "read": false
            ], forDocument: notificationRef)
            
            try await batch.commit()
            
        } catch {
            self.error = "Failed to send friend request: \(error.localizedDescription)"
        }
    }
    
    // ... Continued in next message due to length ...
} 