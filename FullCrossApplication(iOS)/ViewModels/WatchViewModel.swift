import Foundation
import EventKit
import FirebaseFirestore

class WatchViewModel: ObservableObject {
    @Published var viewerCount: Int = Int.random(in: 15...31)
    @Published var streamSettings: StreamSettings?
    private var viewerUpdateTimer: Timer?
    private let db = Firestore.firestore()
    
    init() {
        // Start the viewer count update timer
        startViewerCountUpdates()
        loadStreamSettings()
    }
    
    deinit {
        // Clean up timer when view model is deallocated
        viewerUpdateTimer?.invalidate()
    }
    
    private func startViewerCountUpdates() {
        // Update immediately and then every 25 seconds
        updateViewerCount()
        viewerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            self?.updateViewerCount()
        }
    }
    
    private func updateViewerCount() {
        DispatchQueue.main.async {
            self.viewerCount = Int.random(in: 15...31)
        }
    }
    
    private func loadStreamSettings() {
        db.collection("settings").document("stream")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let document = snapshot?.data() else {
                    print("Error fetching stream settings: \(error?.localizedDescription ?? "No data")")
                    return
                }
                
                DispatchQueue.main.async {
                    let streamUrl = document["streamUrl"] as? String ?? ""
                    let lastUpdated = (document["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedBy = document["updatedBy"] as? String ?? ""
                    
                    self?.streamSettings = StreamSettings(
                        streamUrl: streamUrl,
                        lastUpdated: lastUpdated,
                        updatedBy: updatedBy
                    )
                }
            }
    }
    
    struct StreamSettings {
        let streamUrl: String
        let lastUpdated: Date
        let updatedBy: String
    }
    
    func setReminder(for stream: LiveStream, completion: @escaping (Error?) -> Void = { _ in }) {
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    if granted {
                        let event = EKEvent(eventStore: eventStore)
                        event.title = stream.title
                        event.startDate = stream.startTime
                        event.endDate = stream.startTime.addingTimeInterval(TimeInterval(stream.durationMinutes * 60))
                        event.notes = """
                        Join us for \(stream.title)
                        
                        Watch live at: \(stream.facebookUrl)
                        """
                        event.location = "Facebook Live"
                        event.calendar = eventStore.defaultCalendarForNewEvents
                        
                        // Add 15-minute reminder
                        let alarm = EKAlarm(relativeOffset: -15 * 60) // 15 minutes before
                        event.addAlarm(alarm)
                        
                        try eventStore.save(event, span: .thisEvent)
                        await MainActor.run {
                            completion(nil)
                        }
                    } else {
                        await MainActor.run {
                            completion(NSError(domain: "Calendar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"]))
                        }
                    }
                } catch {
                    await MainActor.run {
                        completion(error)
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted && error == nil {
                        let event = EKEvent(eventStore: eventStore)
                        event.title = stream.title
                        event.startDate = stream.startTime
                        event.endDate = stream.startTime.addingTimeInterval(TimeInterval(stream.durationMinutes * 60))
                        event.notes = """
                        Join us for \(stream.title)
                        
                        Watch live at: \(stream.facebookUrl)
                        """
                        event.location = "Facebook Live"
                        event.calendar = eventStore.defaultCalendarForNewEvents
                        
                        // Add 15-minute reminder
                        let alarm = EKAlarm(relativeOffset: -15 * 60) // 15 minutes before
                        event.addAlarm(alarm)
                        
                        do {
                            try eventStore.save(event, span: .thisEvent)
                            completion(nil)
                        } catch {
                            completion(error)
                        }
                    } else {
                        completion(error ?? NSError(domain: "Calendar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"]))
                    }
                }
            }
        }
    }
} 