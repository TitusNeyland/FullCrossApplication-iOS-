import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FriendsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
    // MARK: - Public Methods
    func loadFriends() {
        Task {
            isLoading = true
            error = nil
            
            do {
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }
                
                let friendshipsSnapshot = try await db.collection("users")
                    .document(currentUserId)
                    .collection("friendships")
                    .getDocuments()
                
                var friendsList: [UserProfile] = []
                
                for doc in friendshipsSnapshot.documents {
                    let friendId = doc.documentID
                    // Skip if somehow the user is in their own friends list
                    if friendId == currentUserId { continue }
                    
                    let status: FriendshipStatus = {
                        switch doc.get("status") as? String {
                        case "pending": return .pending
                        case "accepted": return .accepted
                        case "declined": return .declined
                        default: return .none
                        }
                    }()
                    
                    let userDoc = try await db.collection("users")
                        .document(friendId)
                        .getDocument()
                    
                    if let userData = userDoc.data() {
                        friendsList.append(UserProfile(
                            id: friendId,
                            firstName: userData["firstName"] as? String ?? "",
                            lastName: userData["lastName"] as? String ?? "",
                            phoneNumber: userData["phoneNumber"] as? String ?? "",
                            friendshipStatus: status
                        ))
                    }
                }
                
                friends = friendsList
                
            } catch {
                self.error = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    func sendFriendRequest(_ userId: String) {
        Task {
            do {
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }
                
                // Prevent self-friend requests
                if currentUserId == userId {
                    error = "You cannot send a friend request to yourself"
                    return
                }
                
                let timestamp = Date()
                let batch = db.batch()
                
                // Add to current user's friendships
                let currentUserRef = db.collection("users")
                    .document(currentUserId)
                    .collection("friendships")
                    .document(userId)
                
                batch.setData([
                    "status": "pending",
                    "createdAt": timestamp,
                    "updatedAt": timestamp
                ], forDocument: currentUserRef)
                
                // Add to recipient's friendships
                let recipientRef = db.collection("users")
                    .document(userId)
                    .collection("friendships")
                    .document(currentUserId)
                
                batch.setData([
                    "status": "pending",
                    "createdAt": timestamp,
                    "updatedAt": timestamp
                ], forDocument: recipientRef)
                
                try await batch.commit()
                await loadFriends()
                
            } catch {
                self.error = "Failed to send friend request: \(error.localizedDescription)"
            }
        }
    }
    
    func acceptFriendRequest(_ userId: String) {
        Task {
            do {
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }
                
                let timestamp = Date()
                let batch = db.batch()
                
                // Update current user's friendship
                let currentUserRef = db.collection("users")
                    .document(currentUserId)
                    .collection("friendships")
                    .document(userId)
                
                batch.updateData([
                    "status": "accepted",
                    "updatedAt": timestamp
                ], forDocument: currentUserRef)
                
                // Update other user's friendship
                let otherUserRef = db.collection("users")
                    .document(userId)
                    .collection("friendships")
                    .document(currentUserId)
                
                batch.updateData([
                    "status": "accepted",
                    "updatedAt": timestamp
                ], forDocument: otherUserRef)
                
                try await batch.commit()
                await loadFriends()
                
            } catch {
                self.error = "Failed to accept friend request: \(error.localizedDescription)"
            }
        }
    }
    
    func declineFriendRequest(_ userId: String) {
        Task {
            do {
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }
                
                let batch = db.batch()
                
                // Delete both friendships
                let currentUserRef = db.collection("users")
                    .document(currentUserId)
                    .collection("friendships")
                    .document(userId)
                
                let otherUserRef = db.collection("users")
                    .document(userId)
                    .collection("friendships")
                    .document(currentUserId)
                
                batch.deleteDocument(currentUserRef)
                batch.deleteDocument(otherUserRef)
                
                try await batch.commit()
                await loadFriends()
                
            } catch {
                self.error = "Failed to decline friend request: \(error.localizedDescription)"
            }
        }
    }
} 