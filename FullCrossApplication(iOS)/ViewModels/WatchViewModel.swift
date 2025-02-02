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