import Foundation
import EventKit

class WatchViewModel: ObservableObject {
    @Published var viewerCount: Int = Int.random(in: 15...31)
    @Published var streamSettings: StreamSettings?
    private var viewerUpdateTimer: Timer?
    
    init() {
        // Start the viewer count update timer
        startViewerCountUpdates()
        fetchStreamSettings()
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
    
    private func fetchStreamSettings() {
        // Example stream URL - replace with your actual stream URL
        streamSettings = StreamSettings(streamUrl: "https://www.facebook.com/100079371798055/videos/655144869785669")
    }
    
    struct StreamSettings {
        let streamUrl: String
    }
    
    func setReminder(for stream: LiveStream) {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            if granted && error == nil {
                let event = EKEvent(eventStore: eventStore)
                event.title = stream.title
                event.startDate = stream.startTime
                event.endDate = stream.startTime.addingTimeInterval(TimeInterval(stream.durationMinutes * 60))
                event.notes = "Join us for the live stream at: \(stream.facebookUrl)"
                event.calendar = eventStore.defaultCalendarForNewEvents
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch {
                    print("Error saving event: \(error)")
                }
            }
        }
    }
} 