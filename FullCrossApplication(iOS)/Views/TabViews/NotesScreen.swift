import SwiftUI
import FirebaseAuth

struct NotesScreen: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showAddNoteDialog = false
    @State private var showAddDiscussionDialog = false
    @State private var selectedTab = NotesTab.personalNotes
    @State private var expandedDate: Date?
    
    var navigationTitle: String {
        switch selectedTab {
        case .personalNotes:
            return "Notes"
        case .discussions:
            return "Discussions"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Notes Tab", selection: $selectedTab) {
                    ForEach(NotesTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .frame(maxHeight: 50) // Adjust height if needed
                
                // Content Section
                TabView(selection: $selectedTab) {
                    PersonalNotesView(
                        notes: viewModel.notes,
                        datesWithNotes: viewModel.datesWithNotes,
                        expandedDate: $expandedDate,
                        onDeleteNote: { note in
                            viewModel.deleteNote(note)
                        }
                    )
                    .tag(NotesTab.personalNotes)
                    
                    DiscussionsView(viewModel: viewModel)
                        .tag(NotesTab.discussions)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if selectedTab == .personalNotes {
                            showAddNoteDialog = true
                        } else {
                            showAddDiscussionDialog = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddNoteDialog) {
                AddNoteView(viewModel: viewModel, isPresented: $showAddNoteDialog)
            }
            .sheet(isPresented: $showAddDiscussionDialog) {
                AddDiscussionView(viewModel: viewModel, isPresented: $showAddDiscussionDialog)
            }
        }
    }
}

struct PersonalNotesView: View {
    let notes: [Note]
    let datesWithNotes: Set<Date>
    @Binding var expandedDate: Date?
    let onDeleteNote: (Note) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(datesWithNotes).sorted(by: >), id: \.self) { date in
                    DateCard(
                        date: date,
                        isExpanded: date == expandedDate,
                        notes: date == expandedDate ? notes : [],
                        onExpandClick: {
                            withAnimation {
                                if expandedDate == date {
                                    expandedDate = nil
                                } else {
                                    expandedDate = date
                                }
                            }
                        },
                        onDeleteNote: onDeleteNote
                    )
                }
            }
            .padding()
        }
    }
}

struct DateCard: View {
    let date: Date
    let isExpanded: Bool
    let notes: [Note]
    let onExpandClick: () -> Void
    let onDeleteNote: (Note) -> Void
    @State private var showDeleteDialog = false
    @State private var noteToDelete: Note?
    
    var body: some View {
        VStack(spacing: 0) {
            // Date Header
            Button(action: onExpandClick) {
                HStack {
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Notes List (only when expanded)
            if isExpanded {
                ForEach(notes) { note in
                    Divider()
                    NoteItem(note: note) {
                        noteToDelete = note
                        showDeleteDialog = true
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: isExpanded ? 4 : 1)
        .alert("Delete Note", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    onDeleteNote(note)
                }
            }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }
}

struct NoteItem: View {
    let note: Note
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(note.title)
                        .font(.headline)
                    
                    if let verseRef = note.verseReference {
                        Text(verseRef)
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            Text(note.content)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            HStack {
                Text(note.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                Text(note.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)
            
            Text(note.content)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.secondary)
            
            HStack {
                Text(note.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let verseRef = note.verseReference {
                    Text(verseRef)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(note.type.rawValue)
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DiscussionsView: View {
    let viewModel: NotesViewModel
    
    var body: some View {
        Text("Discussions Coming Soon")
            .foregroundColor(.secondary)
    }
}

struct AddNoteView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var content = ""
    @State private var verseReference = ""
    @State private var noteType = NoteType.general
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(height: 100)
                }
                
                Section {
                    TextField("Verse Reference (Optional)", text: $verseReference)
                }
                
                Section {
                    Picker("Note Type", selection: $noteType) {
                        ForEach([NoteType.general, .verse, .sermon], id: \.self) { type in
                            Text(type.rawValue.capitalized)
                                .tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addNote(
                            title: title,
                            content: content,
                            verseReference: verseReference.isEmpty ? nil : verseReference,
                            type: noteType
                        )
                        isPresented = false
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
} 
