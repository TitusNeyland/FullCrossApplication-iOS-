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
    
    var navigationSubtitle: String {
        switch selectedTab {
        case .personalNotes:
            return "\(viewModel.datesWithNotes.count) days of reflection"
        case .discussions:
            return "Join the conversation"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Enhanced Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(navigationTitle)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(navigationSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Tab Picker
                Picker("Notes Tab", selection: $selectedTab) {
                    ForEach(NotesTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
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
            .navigationBarTitleDisplayMode(.inline)
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
                            .foregroundColor(.primary)
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
    
    private func groupedNotesByDate() -> [(Date, [Note])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notes) { note in
            calendar.startOfDay(for: note.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(groupedNotesByDate(), id: \.0) { date, dateNotes in
                    DateCard(
                        date: date,
                        isExpanded: date == expandedDate,
                        notes: date == expandedDate ? dateNotes : [],
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Date Header
            Button(action: onExpandClick) {
                HStack {
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
                        onDeleteNote(note)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: isExpanded ? 4 : 1)
    }
}

struct NoteItem: View {
    let note: Note
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
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
                
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
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
        .alert("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
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
    @ObservedObject var viewModel: NotesViewModel
    
    var body: some View {
        ScrollView {
            if viewModel.discussions.isEmpty {
                Text("No discussions yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.discussions) { discussion in
                        DiscussionCard(discussion: discussion, viewModel: viewModel)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct DiscussionCard: View {
    let discussion: Discussion
    let viewModel: NotesViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showDiscussionDetail = false
    
    var body: some View {
        Button(action: {
            showDiscussionDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Title and Timestamp
                HStack {
                    Text(discussion.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(formatTimestamp(discussion.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Content
                Text(discussion.content)
                    .font(.body)
                    .lineLimit(3)
                
                // Author and Interaction Stats
                HStack {
                    Text("Posted by \(discussion.authorName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
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
                    }
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showDiscussionDetail) {
            DiscussionDetailView(discussion: discussion, viewModel: viewModel)
                .edgesIgnoringSafeArea(.bottom)
        }
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

// Remove the formatTimestamp function from here 
