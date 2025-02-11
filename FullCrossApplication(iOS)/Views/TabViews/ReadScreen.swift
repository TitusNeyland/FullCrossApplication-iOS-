import SwiftUI
import Combine

struct ReadScreen: View {
    @StateObject private var viewModel: BibleViewModel
    @State private var searchQuery = ""
    @State private var showNoteDialog = false
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showSuccessToast = false
    
    init() {
        // Create the view model on the main actor
        let viewModel = BibleViewModel(
            repository: BibleAPIImpl(apiKey: "7b7279c82199c911590c615bd99cb895"),
            noteRepository: FirestoreNoteRepository()
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Navigation Bar
                    CustomNavigationBar(viewModel: viewModel)
                    
                    // Content
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                if let chapter = viewModel.currentChapter {
                                    ChapterView(
                                        chapter: chapter,
                                        viewModel: viewModel,
                                        showNoteDialog: $showNoteDialog
                                    )
                                } else if let selectedBook = viewModel.selectedBook {
                                    ChapterSelectionView(viewModel: viewModel)
                                } else if viewModel.selectedBible != nil {
                                    BooksList(viewModel: viewModel)
                                } else {
                                    BibleSelectionView(
                                        viewModel: viewModel,
                                        searchQuery: $searchQuery,
                                        scrollOffset: $scrollOffset
                                    )
                                }
                            }
                            .background(GeometryReader { geo in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("scroll")).minY
                                )
                            })
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                        }
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    state = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    if value.translation.width > threshold {
                                        // Swipe right - go to previous chapter
                                        if viewModel.currentChapterIndex > 0,
                                           let bible = viewModel.selectedBible {
                                            Task {
                                                await viewModel.loadPreviousChapter(bibleId: bible.id)
                                            }
                                        }
                                    } else if value.translation.width < -threshold {
                                        // Swipe left - go to next chapter
                                        if viewModel.currentChapterIndex < viewModel.totalChapters - 1,
                                           let bible = viewModel.selectedBible {
                                            Task {
                                                await viewModel.loadNextChapter(bibleId: bible.id)
                                            }
                                        }
                                    }
                                }
                        )
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Visual feedback for swipe
                HStack {
                    if dragOffset > 30 && viewModel.currentChapterIndex > 0 {
                        Image(systemName: "chevron.left.circle.fill")
                            .foregroundColor(.gray)
                            .imageScale(.large)
                            .opacity(min(1.0, dragOffset / 100))
                            .offset(x: dragOffset)
                            .animation(.easeOut, value: dragOffset)
                    }
                    
                    Spacer()
                    
                    if dragOffset < -30 && viewModel.currentChapterIndex < viewModel.totalChapters - 1 {
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundColor(.gray)
                            .imageScale(.large)
                            .opacity(min(1.0, -dragOffset / 100))
                            .offset(x: dragOffset)
                            .animation(.easeOut, value: dragOffset)
                    }
                }
                .padding()
                
                // Add the toast overlay
                if showSuccessToast {
                    ToastView(message: "Successfully added note", systemImage: "checkmark.circle.fill")
                        .transition(.move(edge: .top))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showNoteDialog) {
            if let selectedVerse = viewModel.selectedVerse {
                AddVerseNoteDialog(
                    verseReference: selectedVerse,
                    onDismiss: { showNoteDialog = false },
                    onNoteAdded: { title, content, verseRef in
                        Task {
                            await viewModel.addVerseNote(
                                title: title,
                                content: content,
                                verseReference: verseRef
                            )
                            showNoteDialog = false
                            // Show the success toast
                            withAnimation {
                                showSuccessToast = true
                            }
                            // Hide the toast after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSuccessToast = false
                                }
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Supporting Views
struct CustomNavigationBar: View {
    @ObservedObject var viewModel: BibleViewModel
    
    var title: String {
        if viewModel.currentChapter != nil {
            return "" // Return empty string when viewing a chapter
        } else if viewModel.selectedBook != nil {
            return "Select Chapter"
        } else if viewModel.selectedBible != nil {
            return "Select Book"
        } else {
            return "Select Bible Version"
        }
    }
    
    var body: some View {
        HStack {
            if viewModel.selectedBible != nil {
                Button {
                    if viewModel.currentChapter != nil {
                        viewModel.clearChapter()
                    } else if viewModel.selectedBook != nil {
                        viewModel.setSelectedBook(nil)
                    } else {
                        viewModel.setSelectedBible(nil)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - BibleSelectionView
struct BibleSelectionView: View {
    @ObservedObject var viewModel: BibleViewModel
    @Binding var searchQuery: String
    @Binding var scrollOffset: CGFloat
    
    var filteredBibles: [Bible] {
        if searchQuery.isEmpty {
            return viewModel.bibles
        }
        return viewModel.bibles.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search field
            TextField("Search Bible versions...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            // Verse of the Day card (only show when not searching)
            if searchQuery.isEmpty && scrollOffset > -50 {
                VerseOfDayCard(viewModel: viewModel)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
            
            // Bible versions list
            LazyVStack(spacing: 12) {
                ForEach(filteredBibles) { bible in
                    BibleCard(bible: bible) {
                        viewModel.setSelectedBible(bible)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - BooksList
struct BooksList: View {
    @ObservedObject var viewModel: BibleViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.books) { book in
                    Button {
                        viewModel.setSelectedBook(book)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.name)
                                .font(.headline)
                            
                            if let nameLong = book.nameLong, nameLong != book.name {
                                Text(nameLong)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - ChapterSelectionView
struct ChapterSelectionView: View {
    @ObservedObject var viewModel: BibleViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60), spacing: 16)
            ], spacing: 16) {
                if let chapters = viewModel.selectedBook?.chapters {
                    ForEach(chapters) { chapter in
                        Button {
                            Task {
                                if let bible = viewModel.selectedBible {
                                    await viewModel.loadChapter(bibleId: bible.id, chapterId: chapter.id)
                                }
                            }
                        } label: {
                            Text(chapter.number)
                                .frame(width: 60, height: 60)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - ChapterView
struct ChapterView: View {
    let chapter: Chapter
    @ObservedObject var viewModel: BibleViewModel
    @Binding var showNoteDialog: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Chapter navigation
            HStack {
                Button {
                    if let bible = viewModel.selectedBible {
                        Task {
                            await viewModel.loadPreviousChapter(bibleId: bible.id)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(viewModel.currentChapterIndex == 0 ? .gray : .primary)
                }
                .disabled(viewModel.currentChapterIndex == 0)
                
                Spacer()
                
                if let book = viewModel.selectedBook {
                    Text("\(book.name) \(chapter.number)")
                        .font(.headline)
                }
                
                Spacer()
                
                Button {
                    if let bible = viewModel.selectedBible {
                        Task {
                            await viewModel.loadNextChapter(bibleId: bible.id)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(viewModel.currentChapterIndex == viewModel.totalChapters - 1 ? .gray : .primary)
                }
                .disabled(viewModel.currentChapterIndex == viewModel.totalChapters - 1)
            }
            .padding(.horizontal)
            
            // Chapter content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    let verses = BibleTextFormatter.formatBibleText(chapter.content)
                    
                    if verses.isEmpty {
                        Text("No verses found. Please try another chapter.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(verses, id: \.verseNumber) { verse in
                            Button {
                                viewModel.setSelectedVerse("\(viewModel.selectedBook?.name ?? "") \(chapter.number):\(verse.verseNumber)")
                                showNoteDialog = true
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("[\(verse.verseNumber)]")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                        .frame(width: 30, alignment: .trailing)
                                    
                                    Text(verse.text)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - VerseView
struct VerseView: View {
    let verse: BibleTextFormatter.FormattedVerse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 8) {
                if verse.isVerseStart {
                    Text("[\(verse.verseNumber)]")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .frame(width: 30, alignment: .trailing)
                }
                
                Text(verse.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Components
struct BibleCard: View {
    let bible: Bible
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(bible.name)
                    .font(.headline)
                
                if let description = bible.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(bible.language.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct VerseOfDayCard: View {
    @ObservedObject var viewModel: BibleViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Verse of the Day", systemImage: "sun.max.fill")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    viewModel.refreshVerseOfDay()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.isLoadingVerse {
                ProgressView()
            } else if let verse = viewModel.verseOfDay {
                VStack(spacing: 12) {
                    Text(verse.text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Text(verse.reference)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preference Key for Scroll Offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

