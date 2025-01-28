import Foundation

struct StreamSettings: Codable, Equatable {
    let streamUrl: String
    let lastUpdated: Date
    let updatedBy: String
    
    init(
        streamUrl: String = "",
        lastUpdated: Date = Date(),
        updatedBy: String = ""
    ) {
        self.streamUrl = streamUrl
        self.lastUpdated = lastUpdated
        self.updatedBy = updatedBy
    }
}

// MARK: - Sample Data
extension StreamSettings {
    static let sample = StreamSettings(
        streamUrl: "https://stream.fullcrossministries.org/live",
        updatedBy: "admin"
    )
}

// MARK: - Date Formatting
extension StreamSettings {
    var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
    
    var relativeLastUpdated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
    
    var isStale: Bool {
        // Consider settings stale if older than 24 hours
        return Date().timeIntervalSince(lastUpdated) > 86400
    }
}

// MARK: - URL Validation
extension StreamSettings {
    var isValidUrl: Bool {
        guard let url = URL(string: streamUrl) else { return false }
        return url.scheme?.lowercased() == "https"
    }
    
    var url: URL? {
        URL(string: streamUrl)
    }
} 