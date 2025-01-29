import SwiftUI

struct AddDiscussionView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 120)
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("Share your thoughts...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .navigationTitle("Start a Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        viewModel.addDiscussion(title: title, content: content)
                        isPresented = false
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
} 