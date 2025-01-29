import Foundation

func formatTimestamp(_ timestamp: TimeInterval) -> String {
    let date = Date(timeIntervalSince1970: timestamp)
    let now = Date()
    let diff = now.timeIntervalSince(date)
    
    switch diff {
    case ..<60: // Less than a minute
        return "Just now"
    case ..<3600: // Less than an hour
        let minutes = Int(diff / 60)
        return "\(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
    case ..<86400: // Less than a day
        let hours = Int(diff / 3600)
        return "\(hours) \(hours == 1 ? "hour" : "hours") ago"
    case ..<604800: // Less than a week
        let days = Int(diff / 86400)
        return "\(days) \(days == 1 ? "day" : "days") ago"
    default:
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 