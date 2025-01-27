import SwiftUI

enum BottomNavItem: String, CaseIterable {
    case read = "Read"
    case notes = "Notes"
    case watch = "Watch"
    case donate = "Donate"
    case account = "Account"
    case admin = "Admin"
    
    var icon: String {
        switch self {
        case .read: return "book.fill"
        case .notes: return "square.and.pencil"
        case .watch: return "play.circle.fill"
        case .donate: return "dollarsign.circle.fill"
        case .account: return "person.circle.fill"
        case .admin: return "lock.shield.fill"
        }
    }
    
    var title: String { rawValue }
} 