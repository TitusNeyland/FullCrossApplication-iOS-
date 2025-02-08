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
    
    private func updateSettings(updates: [String: Any]) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Get current settings first
        let snapshot = try await db.collection("settings").document("stream").getDocument()
        var currentSettings = snapshot.data() ?? [:]
        
        // Update only the fields that are provided
        updates.forEach { currentSettings[$0] = $1 }
        
        // Always update these fields
        currentSettings["lastUpdated"] = Timestamp(date: Date())
        currentSettings["updatedBy"] = currentUser.uid
        
        // Save all settings
        try await db.collection("settings").document("stream").setData(currentSettings)
        
        // Update local streamSettings
        let previousServices = (currentSettings["previousServices"] as? [[String: Any]] ?? []).compactMap { data -> StreamSettings.PreviousService? in
            guard let id = data["id"] as? String,
                  let timestamp = data["date"] as? Timestamp,
                  let url = data["url"] as? String else {
                return nil
            }
            return StreamSettings.PreviousService(id: id, date: timestamp.dateValue(), url: url)
        }
        
        self.streamSettings = StreamSettings(
            streamUrl: currentSettings["streamUrl"] as? String ?? "",
            lastUpdated: Date(),
            updatedBy: currentUser.uid,
            previousServices: previousServices,
            monthlyTheme: currentSettings["monthlyTheme"] as? String ?? ""
        )
    }
    
    func updateStreamUrl(_ url: String) async {
        isLoading = true
        do {
            try await updateSettings(updates: ["streamUrl": url])
            self.error = nil
        } catch {
            self.error = "Failed to update stream URL: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func updateMonthlyTheme(_ theme: String) async {
        isLoading = true
        do {
            try await updateSettings(updates: ["monthlyTheme": theme])
            self.error = nil
        } catch {
            self.error = "Failed to update monthly theme: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func addPreviousService(date: Date, url: String) async {
        isLoading = true
        do {
            let newService: [String: Any] = [
                "id": UUID().uuidString,
                "date": Timestamp(date: date),
                "url": url
            ]
            
            var currentServices = streamSettings?.previousServices.map { [
                "id": $0.id,
                "date": Timestamp(date: $0.date),
                "url": $0.url
            ] } ?? []
            currentServices.append(newService)
            
            try await updateSettings(updates: ["previousServices": currentServices])
            self.error = nil
        } catch {
            self.error = "Failed to add previous service: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func deletePreviousService(_ serviceId: String) async {
        isLoading = true
        do {
            let updatedServices = streamSettings?.previousServices.filter { $0.id != serviceId }.map { [
                "id": $0.id,
                "date": Timestamp(date: $0.date),
                "url": $0.url
            ] } ?? []
            
            try await updateSettings(updates: ["previousServices": updatedServices])
            self.error = nil
        } catch {
            self.error = "Failed to delete previous service: \(error.localizedDescription)"
        }
        isLoading = false
    }
} 