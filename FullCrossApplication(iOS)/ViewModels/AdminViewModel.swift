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
                    let monthlyTheme = document["monthlyTheme"] as? String ?? ""
                    
                    // Load previous services
                    let previousServicesData = document["previousServices"] as? [[String: Any]] ?? []
                    let previousServices = previousServicesData.compactMap { data -> StreamSettings.PreviousService? in
                        guard let id = data["id"] as? String,
                              let timestamp = data["date"] as? Timestamp,
                              let url = data["url"] as? String else {
                            return nil
                        }
                        return StreamSettings.PreviousService(
                            id: id,
                            date: timestamp.dateValue(),
                            url: url
                        )
                    }
                    
                    self.streamSettings = StreamSettings(
                        streamUrl: streamUrl,
                        lastUpdated: lastUpdated,
                        updatedBy: updatedBy,
                        previousServices: previousServices,
                        monthlyTheme: monthlyTheme
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
    
    func addPreviousService(date: Date, url: String) async {
        guard let currentUser = auth.currentUser else {
            self.error = "No user logged in"
            return
        }
        
        isLoading = true
        
        do {
            let newService = StreamSettings.PreviousService(
                id: UUID().uuidString,
                date: date,
                url: url
            )
            
            var previousServices = streamSettings?.previousServices ?? []
            previousServices.append(newService)
            
            let settings: [String: Any] = [
                "streamUrl": streamSettings?.streamUrl ?? "",
                "lastUpdated": Timestamp(date: Date()),
                "updatedBy": currentUser.uid,
                "previousServices": previousServices.map { [
                    "id": $0.id,
                    "date": Timestamp(date: $0.date),
                    "url": $0.url
                ]}
            ]
            
            try await db.collection("settings").document("stream").setData(settings)
            
            self.streamSettings?.previousServices = previousServices
            self.error = nil
            self.isLoading = false
        } catch {
            self.error = "Failed to add previous service: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func deletePreviousService(_ serviceId: String) async {
        guard let currentUser = auth.currentUser else {
            self.error = "No user logged in"
            return
        }
        
        isLoading = true
        
        do {
            var previousServices = streamSettings?.previousServices ?? []
            previousServices.removeAll { $0.id == serviceId }
            
            let settings: [String: Any] = [
                "streamUrl": streamSettings?.streamUrl ?? "",
                "lastUpdated": Timestamp(date: Date()),
                "updatedBy": currentUser.uid,
                "previousServices": previousServices.map { [
                    "id": $0.id,
                    "date": Timestamp(date: $0.date),
                    "url": $0.url
                ]}
            ]
            
            try await db.collection("settings").document("stream").setData(settings)
            
            self.streamSettings?.previousServices = previousServices
            self.error = nil
            self.isLoading = false
        } catch {
            self.error = "Failed to delete previous service: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func updateMonthlyTheme(_ theme: String) async {
        guard let currentUser = auth.currentUser else {
            self.error = "No user logged in"
            return
        }
        
        isLoading = true
        
        do {
            let settings: [String: Any] = [
                "streamUrl": streamSettings?.streamUrl ?? "",
                "lastUpdated": Timestamp(date: Date()),
                "updatedBy": currentUser.uid,
                "monthlyTheme": theme,
                "previousServices": streamSettings?.previousServices.map { [
                    "id": $0.id,
                    "date": Timestamp(date: $0.date),
                    "url": $0.url
                ]} ?? []
            ]
            
            try await db.collection("settings").document("stream").setData(settings)
            
            self.streamSettings = StreamSettings(
                streamUrl: streamSettings?.streamUrl ?? "",
                lastUpdated: Date(),
                updatedBy: currentUser.uid,
                previousServices: streamSettings?.previousServices ?? [],
                monthlyTheme: theme
            )
            self.error = nil
            self.isLoading = false
        } catch {
            self.error = "Failed to update monthly theme: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
} 