import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class AdminViewModel: ObservableObject {
    @Published var streamSettings: StreamSettings?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    func loadStreamSettings() {
        isLoading = true
        
        db.collection("settings").document("stream")
            .getDocument { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.error = "Failed to load stream settings: \(error.localizedDescription)"
                        self.isLoading = false
                        return
                    }
                    
                    guard let document = snapshot?.data() else {
                        self.error = "No stream settings found"
                        self.isLoading = false
                        return
                    }
                    
                    let streamUrl = document["streamUrl"] as? String ?? ""
                    let lastUpdated = (document["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedBy = document["updatedBy"] as? String ?? ""
                    
                    self.streamSettings = StreamSettings(
                        streamUrl: streamUrl,
                        lastUpdated: lastUpdated,
                        updatedBy: updatedBy
                    )
                    self.error = nil
                    self.isLoading = false
                }
            }
    }
    
    func updateStreamUrl(_ url: String) async {
        guard let currentUser = auth.currentUser else {
            self.error = "No user logged in"
            return
        }
        
        isLoading = true
        
        do {
            let settings = [
                "streamUrl": url,
                "lastUpdated": Timestamp(date: Date()),
                "updatedBy": currentUser.uid
            ] as [String : Any]
            
            try await db.collection("settings").document("stream").setData(settings)
            
            self.streamSettings = StreamSettings(
                streamUrl: url,
                lastUpdated: Date(),
                updatedBy: currentUser.uid
            )
            self.error = nil
            self.isLoading = false
        } catch {
            self.error = "Failed to update stream URL: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
} 