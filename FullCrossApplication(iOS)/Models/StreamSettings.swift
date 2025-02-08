import Foundation

struct StreamSettings: Equatable {
    let streamUrl: String
    let lastUpdated: Date
    let updatedBy: String
    var previousServices: [PreviousService]
    let monthlyTheme: String
    
    init(streamUrl: String = "", lastUpdated: Date = Date(), updatedBy: String = "", previousServices: [PreviousService] = [], monthlyTheme: String = "") {
        self.streamUrl = streamUrl
        self.lastUpdated = lastUpdated
        self.updatedBy = updatedBy
        self.previousServices = previousServices
        self.monthlyTheme = monthlyTheme
    }
    
    static func == (lhs: StreamSettings, rhs: StreamSettings) -> Bool {
        return lhs.streamUrl == rhs.streamUrl &&
               lhs.lastUpdated == rhs.lastUpdated &&
               lhs.updatedBy == rhs.updatedBy &&
               lhs.monthlyTheme == rhs.monthlyTheme
    }
    
    struct PreviousService: Identifiable, Equatable {
        let id: String
        let date: Date
        let url: String
        
        static func == (lhs: PreviousService, rhs: PreviousService) -> Bool {
            return lhs.id == rhs.id && lhs.date == rhs.date && lhs.url == rhs.url
        }
    }
} 