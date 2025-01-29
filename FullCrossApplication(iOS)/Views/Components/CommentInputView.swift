import SwiftUI

struct CommentInputView: View {
    @Binding var text: String
    let placeholder: String
    let onSend: () -> Void
    let onCancelReply: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(text.isEmpty ? .gray : .blue)
                }
                .disabled(text.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
} 