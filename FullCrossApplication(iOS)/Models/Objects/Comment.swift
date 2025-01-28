import Foundation

struct Comment: Identifiable, Codable, Equatable {
    let id: String
    let discussionId: String
    let content: String
    let authorId: String
    let authorName: String
    let timestamp: Date
    let likes: Int
    let parentCommentId: String?
    let replyToAuthorName: String?
    let replyCount: Int
    let isReply: Boolean
    
    init(
        id: String = UUID().uuidString,
        discussionId: String = "",
        content: String = "",
        authorId: String = "",
        authorName: String = "",
        timestamp: Date = Date(),
        likes: Int = 0,
        parentCommentId: String? = nil,
        replyToAuthorName: String? = nil,
        replyCount: Int = 0,
        isReply: Bool = false
    ) {
        self.id = id
        self.discussionId = discussionId
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.timestamp = timestamp
        self.likes = likes
        self.parentCommentId = parentCommentId
        self.replyToAuthorName = replyToAuthorName
        self.replyCount = replyCount
        self.isReply = isReply
    }
}

// MARK: - Sample Data
extension Comment {
    static let sample = Comment(
        discussionId: "disc123",
        content: "This is such an important topic. Grace is what transforms us daily.",
        authorId: "user789",
        authorName: "Sarah Wilson",
        likes: 2
    )
    
    static let samples = [
        sample,
        Comment(
            discussionId: "disc123",
            content: "Amen! Grace is unmerited favor.",
            authorId: "user101",
            authorName: "David Brown",
            parentCommentId: sample.id,
            replyToAuthorName: sample.authorName,
            isReply: true
        )
    ]
} 