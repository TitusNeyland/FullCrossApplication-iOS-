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
                                    Text("\(discussion.likes)")
                                }
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.right")
                                Text("\(discussion.commentCount)")
                            }
                            
                            Spacer()
                            
                            Text(Date(timeIntervalSince1970: discussion.timestamp), style: .relative)
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
                        
                        ForEach(discussion.comments) { comment in
                            CommentView(
                                comment: comment,
                                onReply: { replyingTo = comment },
                                onDelete: {
                                    viewModel.deleteComment(discussionId: discussion.id, commentId: comment.id)
                                }
                            )
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            
            // Comment Input
            VStack {
                if let replyingTo = replyingTo {
                    HStack {
                        Text("Replying to \(replyingTo.authorName)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: { self.replyingTo = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
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
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
    }
}

struct CommentView: View {
    let comment: Comment
    let onReply: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
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
                            .foregroundColor(.red)
                    }
                }
            }
            
            if let replyToAuthorName = comment.replyToAuthorName {
                Text("Replying to \(replyToAuthorName)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text(comment.content)
                .font(.body)
            
            HStack {
                Text(Date(timeIntervalSince1970: comment.timestamp), style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !comment.isReply {
                    Button("Reply", action: onReply)
                        .font(.caption)
                }
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