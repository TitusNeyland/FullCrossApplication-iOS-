import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published private(set) var notifications: [Notification] = []
    @Published private(set) var unreadCount: Int = 0
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        setupNotificationsListener()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    private func setupNotificationsListener() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let notificationsRef = db.collection("users")
            .document(currentUserId)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
        
        listenerRegistration = notificationsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, error == nil else { return }
            
            guard let documents = snapshot?.documents else {
                self.notifications = []
                self.unreadCount = 0
                return
            }
            
            self.notifications = documents.compactMap { doc -> Notification? in
                guard let type = doc.get("type") as? String,
                      let notificationType = NotificationType(rawValue: type) else {
                    return nil
                }
                
                return Notification(
                    id: doc.documentID,
                    type: notificationType,
                    fromUserId: doc.get("fromUserId") as? String ?? "",
                    fromUserName: doc.get("fromUserName") as? String ?? "",
                    timestamp: (doc.get("timestamp") as? Timestamp)?.dateValue() ?? Date(),
                    read: doc.get("read") as? Bool ?? false
                )
            }
            
            self.unreadCount = self.notifications.filter { !$0.read }.count
        }
    }
    
    func markAsRead(_ notificationId: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users")
                .document(currentUserId)
                .collection("notifications")
                .document(notificationId)
                .updateData(["read": true])
        } catch {
            print("Error marking notification as read: \(error.localizedDescription)")
        }
    }
    
    func loadNotifications() {
        // This method is not needed in iOS as we're using real-time listeners
        // The setupNotificationsListener handles this functionality
    }
} 