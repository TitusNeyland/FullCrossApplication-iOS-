import SwiftUI

struct AddDiscussionView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Binding var isPresented: Bool
    @State private var showSuccessToast = false
    
    @State private var title = ""
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            ZStack {
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
                
                if showSuccessToast {
                    ToastView(message: "Discussion posted", systemImage: "checkmark.circle.fill")
                        .transition(.move(edge: .top))
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
                        // Show the success toast
                        withAnimation {
                            showSuccessToast = true
                        }
                        // Dismiss the view after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            isPresented = false
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
} 