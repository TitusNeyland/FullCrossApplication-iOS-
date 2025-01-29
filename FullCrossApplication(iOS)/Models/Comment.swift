import Foundation

struct Comment: Identifiable {
    let id: String
    let discussionId: String
    let content: String
    let authorId: String
    let authorName: String
    let timestamp: TimeInterval
    let likes: Int
    let parentCommentId: String?
    let replyToAuthorName: String?
    let replyCount: Int
    let isReply: Bool
    
    init(
        id: String = "",
        discussionId: String = "",
        content: String = "",
        authorId: String = "",
        authorName: String = "",
        timestamp: TimeInterval = Date().timeIntervalSince1970,
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
