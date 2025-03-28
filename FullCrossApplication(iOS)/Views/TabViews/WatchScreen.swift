import SwiftUI
import EventKit

enum WatchScreenTab {
    case watch
    case friends
}

struct WatchScreen: View {
    @StateObject private var watchViewModel = WatchViewModel()
    @StateObject private var notificationsViewModel = NotificationsViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var contactsViewModel: ContactsViewModel
    
    @State private var selectedTab = WatchScreenTab.watch
    @State private var showSocialDialog = false
    
    init() {
        // Initialize ContactsViewModel with AuthViewModel
        _contactsViewModel = StateObject(wrappedValue: ContactsViewModel(authViewModel: AuthViewModel()))
    }
    
    private var currentMonthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Enhanced Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Watch Now")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("View the latest live broadcast here")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .overlay(alignment: .trailing) {
                    Button(action: { showSocialDialog = true }) {
                        ZStack {
                            Image(systemName: "person.2")
                                .font(.title2)
                                .foregroundColor(.primary)
                            
                            if notificationsViewModel.unreadCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                    Text("\(notificationsViewModel.unreadCount)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 20, height: 20)
                                .offset(x: 10, y: -10)
                            }
                        }
                    }
                    .padding(.trailing)
                }
                
                // Video Player Section
                LazyVStack(spacing: 16) {
                    // Monthly Theme Section (moved closer to video player)
                    if let theme = watchViewModel.streamSettings?.monthlyTheme,
                       !theme.isEmpty {
                        HStack(spacing: 4) {
                            Text("\(currentMonthName)'s Theme:")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text(theme)
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Featured Live Stream
                    FeaturedStreamCard(
                        stream: LiveStream(
                            title: "Sunday Morning Service",
                            thumbnailUrl: "https://example.com/thumbnail.jpg",
                            startTime: Date(),
                            durationMinutes: 60,
                            viewerCount: watchViewModel.viewerCount,
                            isLive: true,
                            facebookUrl: "https://www.facebook.com/profile.php?id=100079371798055"
                        )
                    )
                    
                    // Upcoming Streams Section
                    Text("Upcoming Services")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                    
                    // Example upcoming streams
                    ForEach(LiveStream.getUpcomingStreams()) { stream in
                        UpcomingStreamCard(stream: stream)
                    }
                    
                    // Previous Streams Section
                    Text("Previous Services")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                    
                    if LiveStream.getPreviousStreams().isEmpty {
                        Text("There are no previous streams at the moment")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(LiveStream.getPreviousStreams()) { stream in
                            PreviousStreamCard(stream: stream, watchViewModel: watchViewModel)
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showSocialDialog) {
            SocialConnectionDialog(
                contactsViewModel: contactsViewModel,
                notificationsViewModel: notificationsViewModel,
                onDismiss: { showSocialDialog = false }
            )
        }
    }
}

struct FeaturedStreamCard: View {
    let stream: LiveStream
    @StateObject private var watchViewModel = WatchViewModel()
    @Environment(\.openURL) private var openURL
    @State private var showPermissionAlert = false
    
    var body: some View {
        Card {
            VStack(spacing: 0) {
                // Image section with dynamic height
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image("cross.logo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.25) // Dynamic height based on screen size
                    
                    // Actual image
                    AsyncImage(url: URL(string: stream.thumbnailUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        EmptyView()
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.25) // Match the container height
                    .clipped()
                    
                    // Live indicator
                    if stream.isLive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(8)
                    }
                }
                
                // Content section with adaptive spacing
                VStack(alignment: .leading, spacing: 12) {
                    Text(stream.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top, UIScreen.main.bounds.height * 0.04) // Dynamic top padding
                    
                    HStack {
                        Image(systemName: "eye")
                            .font(.caption)
                        Text("\(stream.viewerCount) watching")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Button {
                        if let streamUrl = watchViewModel.streamSettings?.streamUrl,
                           !streamUrl.isEmpty,
                           let url = URL(string: streamUrl) {
                            openURL(url)
                        } else if let url = URL(string: stream.facebookUrl) {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Join Stream")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 8)
                }
                .padding(20)
            }
        }
        .alert("Calendar Access", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Calendar permission is needed to set reminders for upcoming services.")
        }
    }
}

struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct UpcomingStreamCard: View {
    let stream: LiveStream
    @StateObject private var watchViewModel = WatchViewModel()
    @State private var showPermissionAlert = false
    @State private var showSuccessToast = false
    
    var body: some View {
        Card {
            HStack(spacing: 16) {
                // Time column
                VStack(alignment: .trailing) {
                    Text(timeString)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(dayString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 72)
                
                // Divider
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 40)
                
                // Content column
                VStack(alignment: .leading, spacing: 4) {
                    Text(stream.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(stream.durationMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Reminder button
                Button {
                    watchViewModel.setReminder(for: stream) { error in
                        if error == nil {
                            withAnimation {
                                showSuccessToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSuccessToast = false
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "bell")
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
        .alert("Calendar Access", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Calendar permission is needed to set reminders for upcoming services.")
        }
        .overlay {
            if showSuccessToast {
                ToastView(message: "Added to Calendar", systemImage: "checkmark.circle.fill")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSuccessToast = false
                            }
                        }
                    }
            }
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: stream.startTime)
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: stream.startTime)
    }
}

struct PreviousStreamCard: View {
    let stream: LiveStream
    @Environment(\.openURL) private var openURL
    @ObservedObject var watchViewModel: WatchViewModel
    
    var body: some View {
        Card {
            HStack(spacing: 16) {
                // Time column
                VStack(alignment: .trailing) {
                    Text(dateString)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(timeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(width: 72)
                
                // Divider
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 40)
                
                // Content column
                VStack(alignment: .leading, spacing: 4) {
                    Text(stream.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(stream.durationMinutes) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Watch Recording button
                Button {
                    let url = stream.getVideoUrl(watchViewModel: watchViewModel)
                    if let url = URL(string: url) {
                        openURL(url)
                    }
                } label: {
                    Image(systemName: "play.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: stream.startTime)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: stream.startTime)
    }
} 
