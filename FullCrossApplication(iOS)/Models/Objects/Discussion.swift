import Foundation

struct Discussion: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let content: String
    let authorId: String
    let authorName: String
    let timestamp: Date
    let likes: Int
    let commentCount: Int
    let tags: [String]
    let comments: [Comment]
    let likedByUsers: Set<String>
    
    init(
        id: String = UUID().uuidString,
        title: String = "",
        content: String = "",
        authorId: String = "",
        authorName: String = "",
        timestamp: Date = Date(),
        likes: Int = 0,
        commentCount: Int = 0,
        tags: [String] = [],
        comments: [Comment] = [],
        likedByUsers: Set<String> = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.timestamp = timestamp
        self.likes = likes
        self.commentCount = commentCount
        self.tags = tags
        self.comments = comments
        self.likedByUsers = likedByUsers
    }
}

// MARK: - Sample Data
extension Discussion {
    static let sample = Discussion(
        title: "Understanding Grace",
        content: "What does grace mean to you in your daily walk with Christ?",
        authorId: "user123",
        authorName: "John Smith",
        tags: ["Faith", "Grace", "Discussion"],
        comments: [Comment.sample]
    )
    
    static let samples = [
        sample,
        Discussion(
            title: "Prayer Request",
            content: "Please pray for my family during this difficult time.",
            authorId: "user456",
            authorName: "Mary Johnson",
            tags: ["Prayer", "Support"],
            likes: 5,
            commentCount: 3
        )
    ]
} 