import Foundation
import EventKit

class WatchViewModel: ObservableObject {
    @Published var viewerCount: Int = 0
    @Published var streamSettings: StreamSettings?
    
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