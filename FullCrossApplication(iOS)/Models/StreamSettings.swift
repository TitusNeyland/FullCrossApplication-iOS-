import Foundation

struct StreamSettings: Equatable {
    let streamUrl: String
    let lastUpdated: Date
    let updatedBy: String
    
    init(streamUrl: String = "", lastUpdated: Date = Date(), updatedBy: String = "") {
        self.streamUrl = streamUrl
        self.lastUpdated = lastUpdated
        self.updatedBy = updatedBy
    }
    
    static func == (lhs: StreamSettings, rhs: StreamSettings) -> Bool {
        return lhs.streamUrl == rhs.streamUrl &&
               lhs.lastUpdated == rhs.lastUpdated &&
               lhs.updatedBy == rhs.updatedBy
    }
} 