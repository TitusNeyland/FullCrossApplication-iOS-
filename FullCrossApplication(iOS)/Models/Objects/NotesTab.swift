import Foundation

enum NotesTab: String, CaseIterable, Identifiable {
    case personalNotes = "PERSONAL_NOTES"
    case discussions = "DISCUSSIONS"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .personalNotes:
            return "Personal Notes"
        case .discussions:
            return "Discussions"
        }
    }
    
    var iconName: String {
        switch self {
        case .personalNotes:
            return "note.text"
        case .discussions:
            return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Default Tab
extension NotesTab {
    static var defaultTab: NotesTab {
        .personalNotes
    }
} 