import Foundation

struct Discussion: Identifiable {
    let id: String
    let title: String
    let content: String
    let authorId: String
    let authorName: String
    let timestamp: TimeInterval
    let likes: Int
    let commentCount: Int
    let tags: [String]
    let comments: [Comment]
    let likedByUsers: Set<String>
    
    init(
        id: String = "",
        title: String = "",
        content: String = "",
        authorId: String = "",
        authorName: String = "",
        timestamp: TimeInterval = Date().timeIntervalSince1970,
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