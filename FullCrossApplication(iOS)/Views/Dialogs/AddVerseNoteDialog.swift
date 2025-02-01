import SwiftUI

struct AddVerseNoteDialog: View {
    let verseReference: String
    let onDismiss: () -> Void
    let onNoteAdded: (String, String, String) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Verse: \(verseReference)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $content)
                        .frame(height: 120)
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("Notes")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .navigationTitle("Add Verse Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !title.isEmpty && !content.isEmpty {
                            onNoteAdded(title, content, verseReference)
                            onDismiss()
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AddVerseNoteDialog(
        verseReference: "John 3:16",
        onDismiss: {},
        onNoteAdded: { _, _, _ in }
    )
} 