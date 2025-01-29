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
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            VStack(alignment: .leading, spacing: 4) {
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
                        
                        if notificationsViewModel.unreadCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .padding(.trailing)
            }
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Featured Live Stream
                    FeaturedStreamCard(
                        stream: LiveStream(
                            title: "Sunday Morning Service",
                            thumbnailUrl: "https://example.com/thumbnail.jpg",
                            startTime: Date(),
                            durationMinutes: 60,
                            viewerCount: watchViewModel.viewerCount,
                            isLive: true,
                            facebookUrl: "https://www.facebook.com/100079371798055/videos/655144869785669"
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
                }
                .padding()
            }
        }
        .sheet(isPresented: $showSocialDialog) {
            SocialConnectionDialog(
                onDismiss: { showSocialDialog = false }
            )
        }
    }
}

struct FeaturedStreamCard: View {
    let stream: LiveStream
    @StateObject private var watchViewModel = WatchViewModel()
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Card {
            VStack(spacing: 0) {
                // Image section
                ZStack(alignment: .topLeading) {
                    // Placeholder/Loading state
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "play.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                        .frame(height: 200)
                    
                    // Actual image
                    AsyncImage(url: URL(string: stream.thumbnailUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        // Placeholder is already showing
                        EmptyView()
                    }
                    .frame(height: 200)
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
                
                // Content section
                VStack(alignment: .leading, spacing: 8) {
                    Text(stream.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "eye")
                            .font(.caption)
                        Text("\(stream.viewerCount) watching")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Button {
                        if let streamUrl = watchViewModel.streamSettings?.streamUrl,
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
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
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
                    requestCalendarAccess()
                } label: {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(.accentColor)
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
    
    private func requestCalendarAccess() {
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    if granted {
                        await addEventToCalendar(store: eventStore)
                    } else {
                        showPermissionAlert = true
                    }
                } catch {
                    showPermissionAlert = true
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                if granted && error == nil {
                    Task { @MainActor in
                        await addEventToCalendar(store: eventStore)
                    }
                } else {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func addEventToCalendar(store: EKEventStore) async {
        do {
            let event = EKEvent(eventStore: store)
            event.title = stream.title
            event.startDate = stream.startTime
            event.endDate = stream.startTime.addingTimeInterval(TimeInterval(stream.durationMinutes * 60))
            event.notes = "Join us for the live stream at: \(stream.facebookUrl)"
            event.calendar = store.defaultCalendarForNewEvents
            
            try store.save(event, span: .thisEvent)
        } catch {
            print("Error saving event: \(error.localizedDescription)")
        }
    }
}

struct SocialConnectionDialog: View {
    let onDismiss: () -> Void
    
    @StateObject private var contactsViewModel: ContactsViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @State private var searchQuery = ""
    @State private var isSyncExpanded = false
    @State private var isFindFriendsExpanded = false
    @Environment(\.openURL) private var openURL
    
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        // Initialize ContactsViewModel with AuthViewModel
        _contactsViewModel = StateObject(wrappedValue: ContactsViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Friend Requests Section
                    friendRequestsSection
                    
                    // Find Friends Section
                    findFriendsSection
                    
                    Divider()
                    
                    // Sync Contacts Section
                    syncContactsSection
                    
                    // Refer Friends Button
                    referFriendsButton
                }
                .padding()
            }
            .navigationTitle("Connect with Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private var friendRequestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Friend Requests")
                .font(.headline)
            
            ForEach(notificationsViewModel.notifications.filter { $0.type == .friendRequest && !$0.read }) { request in
                FriendRequestCard(
                    request: request,
                    contactsViewModel: contactsViewModel,
                    notificationsViewModel: notificationsViewModel
                )
            }
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    private var findFriendsSection: some View {
        VStack(spacing: 8) {
            DisclosureGroup(
                isExpanded: $isFindFriendsExpanded,
                content: {
                    VStack(spacing: 12) {
                        SearchBar(text: $searchQuery)
                            .onChange(of: searchQuery) { newValue in
                                Task {
                                    await contactsViewModel.searchUsers(newValue)
                                }
                            }
                        
                        if contactsViewModel.isSearching {
                            ProgressView()
                                .padding()
                        } else if !contactsViewModel.searchResults.isEmpty {
                            ForEach(contactsViewModel.searchResults) { user in
                                SearchResultRow(
                                    user: user,
                                    contactsViewModel: contactsViewModel
                                )
                            }
                        } else if searchQuery.count >= 2 {
                            Text("No users found")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                },
                label: {
                    Label("Find Friends", systemImage: "magnifyingglass")
                        .font(.headline)
                }
            )
        }
    }
    
    private var syncContactsSection: some View {
        VStack(spacing: 8) {
            DisclosureGroup(
                isExpanded: $isSyncExpanded,
                content: {
                    if contactsViewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if !contactsViewModel.contacts.isEmpty {
                        ForEach(contactsViewModel.contacts) { contact in
                            ContactRow(contact: contact)
                        }
                    }
                },
                label: {
                    Label("Sync Contacts", systemImage: "person.crop.circle.badge.plus")
                        .font(.headline)
                }
            )
            .onChange(of: isSyncExpanded) { expanded in
                if expanded && contactsViewModel.contacts.isEmpty {
                    Task {
                        await contactsViewModel.syncContacts()
                    }
                }
            }
        }
    }
    
    private var referFriendsButton: some View {
        Button {
            let message = "Join me on our church app! Download it here: [Your App Link]"
            let url = URL(string: "sms:&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
            if let url = url {
                openURL(url)
            }
        } label: {
            Label("Refer Friends", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search by name or phone", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct FriendRequestCard: View {
    let request: Notification
    let contactsViewModel: ContactsViewModel
    let notificationsViewModel: NotificationsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(request.fromUserName)
                    .font(.headline)
                Text("Sent you a friend request")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button("Accept") {
                    Task {
                        await contactsViewModel.acceptFriendRequest(request.fromUserId)
                        await notificationsViewModel.markAsRead(request.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Decline") {
                    Task {
                        await contactsViewModel.declineFriendRequest(request.fromUserId)
                        await notificationsViewModel.markAsRead(request.id)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SearchResultRow: View {
    let user: UserProfile
    let contactsViewModel: ContactsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.fullName)
                    .font(.headline)
                if !user.phoneNumber.isEmpty {
                    Text(user.phoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            switch user.friendshipStatus {
            case .none:
                Button("Add Friend") {
                    Task {
                        await contactsViewModel.sendFriendRequest(toUserId: user.id, toUserName: user.fullName)
                    }
                }
                .foregroundColor(.green)
                
            case .pending:
                Text("Pending")
                    .foregroundColor(.secondary)
                
            case .accepted:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
            case .declined:
                Button("Try Again") {
                    Task {
                        await contactsViewModel.sendFriendRequest(toUserId: user.id, toUserName: user.fullName)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ContactRow: View {
    let contact: Contact
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact.name)
                    .font(.headline)
                if let phone = contact.phoneNumber {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if contact.isAppUser {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Invite") {
                    let message = "Join me on our church app! Download it here: [Your App Link]"
                    if let phone = contact.phoneNumber,
                       let url = URL(string: "sms:\(phone)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                        openURL(url)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }
} 