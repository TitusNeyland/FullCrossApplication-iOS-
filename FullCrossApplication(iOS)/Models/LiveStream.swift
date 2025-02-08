import Foundation

struct LiveStream: Identifiable {
    let id = UUID()
    let title: String
    let thumbnailUrl: String
    let startTime: Date
    let durationMinutes: Int
    let viewerCount: Int
    let isLive: Bool
    let facebookUrl: String
    
    func getVideoUrl(watchViewModel: WatchViewModel) -> String {
        // If there's a specific URL for this date, use it
        if let specificUrl = watchViewModel.getUrlForPreviousService(date: startTime) {
            return specificUrl
        }
        // Otherwise fall back to the default Facebook URL
        return facebookUrl
    }
    
    static func getUpcomingStreams() -> [LiveStream] {
        let calendar = Calendar.current
        
        // Get next Wednesday at 6 PM
        var nextWednesdayComponents = DateComponents()
        nextWednesdayComponents.weekday = 4 // Wednesday
        nextWednesdayComponents.hour = 18
        nextWednesdayComponents.minute = 0
        let nextWednesday = calendar.nextDate(after: Date(), matching: nextWednesdayComponents, matchingPolicy: .nextTime) ?? Date()
        
        // Get next Sunday at 9 AM
        var nextSundayComponents = DateComponents()
        nextSundayComponents.weekday = 1 // Sunday
        nextSundayComponents.hour = 9
        nextSundayComponents.minute = 0
        let nextSunday = calendar.nextDate(after: Date(), matching: nextSundayComponents, matchingPolicy: .nextTime) ?? Date()
        
        return [
            LiveStream(
                title: "Wednesday Bible Study",
                thumbnailUrl: "https://example.com/thumbnail1.jpg",
                startTime: nextWednesday,
                durationMinutes: 50,
                viewerCount: 0,
                isLive: false,
                facebookUrl: "https://www.facebook.com/profile.php?id=100079371798055"
            ),
            LiveStream(
                title: "Sunday Morning Service",
                thumbnailUrl: "https://example.com/thumbnail2.jpg",
                startTime: nextSunday,
                durationMinutes: 50,
                viewerCount: 0,
                isLive: false,
                facebookUrl: "https://www.facebook.com/profile.php?id=100079371798055"
            )
        ].sorted { $0.startTime < $1.startTime }
    }
    
    static func getPreviousStreams() -> [LiveStream] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get last Sunday and Wednesday
        var lastSundayComponents = DateComponents()
        lastSundayComponents.weekday = 1 // Sunday
        lastSundayComponents.hour = 9
        lastSundayComponents.minute = 0
        let lastSunday = calendar.nextDate(
            after: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            matching: lastSundayComponents,
            matchingPolicy: .previousTimePreservingSmallerComponents
        ) ?? now
        
        var lastWednesdayComponents = DateComponents()
        lastWednesdayComponents.weekday = 4 // Wednesday
        lastWednesdayComponents.hour = 18
        lastWednesdayComponents.minute = 0
        let lastWednesday = calendar.nextDate(
            after: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            matching: lastWednesdayComponents,
            matchingPolicy: .previousTimePreservingSmallerComponents
        ) ?? now
        
        let streams = [
            LiveStream(
                title: "Wednesday Bible Study",
                thumbnailUrl: "https://example.com/thumbnail1.jpg",
                startTime: lastWednesday,
                durationMinutes: 50,
                viewerCount: 0,
                isLive: false,
                facebookUrl: "https://www.facebook.com/profile.php?id=100079371798055"
            ),
            LiveStream(
                title: "Sunday Morning Service",
                thumbnailUrl: "https://example.com/thumbnail2.jpg",
                startTime: lastSunday,
                durationMinutes: 50,
                viewerCount: 0,
                isLive: false,
                facebookUrl: "https://www.facebook.com/profile.php?id=100079371798055"
            )
        ]
        
        return streams.filter { $0.startTime < now }.sorted { $0.startTime > $1.startTime }
    }
} 
