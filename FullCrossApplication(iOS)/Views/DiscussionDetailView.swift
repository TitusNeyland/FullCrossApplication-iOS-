import SwiftUI
import Firebase
import FirebaseAuth

struct DiscussionDetailView: View {
    let discussion: Discussion
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newComment = ""
    @State private var replyingTo: Comment?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Discussion Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text(discussion.title)
                                .font(.title2)
                                .bold()
                            
                            Text("Posted by \(discussion.authorName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(discussion.content)
                                .font(.body)
                                .padding(.top, 4)
                            
                            HStack(spacing: 16) {
                                Button(action: {
                                    viewModel.likeDiscussion(discussion.id)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: discussion.likedByUsers.contains(Auth.auth().currentUser?.uid ?? "") ? "heart.fill" : "heart")
                                            .foregroundColor(.primary)
                                        Text("\(discussion.likes)")
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.right")
                                        .foregroundColor(.secondary)
                                    Text("\(discussion.commentCount)")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(formatTimestamp(discussion.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        
                        // Comments Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comments")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(discussion.comments.filter { !$0.isReply }) { comment in
                                CommentView(
                                    comment: comment,
                                    onReply: { replyingTo = comment },
                                    onDelete: {
                                        viewModel.deleteComment(discussionId: discussion.id, commentId: comment.id)
                                    },
                                    viewModel: viewModel,
                                    discussionId: discussion.id
                                )
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 60) // Add padding for the input field
                }
                
                // Persistent comment input
                VStack(spacing: 0) {
                    if let replyingTo = replyingTo {
                        HStack {
                            Text("Replying to \(replyingTo.authorName)")
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: { self.replyingTo = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .background(Color(.systemBackground))
                    }
                    
                    CommentInputView(
                        text: $newComment,
                        placeholder: replyingTo != nil ? "Write a reply..." : "Add a comment",
                        onSend: {
                            if !newComment.isEmpty {
                                viewModel.addComment(
                                    discussionId: discussion.id,
                                    content: newComment,
                                    parentCommentId: replyingTo?.id,
                                    replyToAuthorName: replyingTo?.authorName
                                )
                                newComment = ""
                                replyingTo = nil
                            }
                        },
                        onCancelReply: replyingTo != nil ? { replyingTo = nil } : nil
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CommentView: View {
    let comment: Comment
    let onReply: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    @State private var showReplies = false
    @ObservedObject var viewModel: NotesViewModel
    let discussionId: String
    
    private var replies: [Comment] {
        viewModel.discussions
            .first(where: { $0.id == discussionId })?
            .comments
            .filter { $0.parentCommentId == comment.id } ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.authorName)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                if comment.authorId == Auth.auth().currentUser?.uid {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let replyToAuthorName = comment.replyToAuthorName {
                Text("Replying to \(replyToAuthorName)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            Text(comment.content)
                .font(.body)
            
            HStack {
                Text(formatTimestamp(comment.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !comment.isReply {
                    if comment.replyCount > 0 {
                        Button(action: { 
                            withAnimation {
                                showReplies.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(showReplies ? "Hide replies" : "Show \(comment.replyCount) replies")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                Image(systemName: showReplies ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Button("Reply", action: onReply)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(.leading, 8)
                }
            }
            
            if showReplies && !replies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(replies) { reply in
                        Divider()
                        CommentView(
                            comment: reply,
                            onReply: onReply,
                            onDelete: {
                                viewModel.deleteComment(discussionId: discussionId, commentId: reply.id)
                            },
                            viewModel: viewModel,
                            discussionId: discussionId
                        )
                        .padding(.leading, 16)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
} 