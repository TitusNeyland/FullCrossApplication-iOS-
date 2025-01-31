import SwiftUI
import ContactsUI
import FirebaseAuth

struct SocialConnectionDialog: View {
    @ObservedObject var contactsViewModel: ContactsViewModel
    @ObservedObject var notificationsViewModel: NotificationsViewModel
    @State private var isSyncExpanded = false
    @State private var isFindFriendsExpanded = false
    @State private var searchQuery = ""
    let onDismiss: () -> Void
    
    private var friendRequests: [Notification] {
        notificationsViewModel.notifications.filter { 
            $0.type == .friendRequest && !$0.read 
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Friend Requests Section
                    if !friendRequests.isEmpty {
                        friendRequestsSection
                    }
                    
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
                    Button("Close", action: onDismiss)
                }
            }
        }
    }
    
    private var friendRequestsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Friend Requests (\(friendRequests.count))")
                .font(.headline)
            
            ForEach(friendRequests) { request in
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
                        ContactsList(contacts: contactsViewModel.contacts)
                    }
                },
                label: {
                    HStack {
                        Label("Sync Contacts", systemImage: "person.crop.circle.badge.plus")
                            .font(.headline)
                        
                        Spacer()
                        
                        if contactsViewModel.contacts.isEmpty {
                            Button("Sync") {
                                Task {
                                    await contactsViewModel.syncContacts()
                                    isSyncExpanded = true
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            )
        }
    }
    
    private var referFriendsButton: some View {
        ShareLink(
            item: "Join me on this amazing journey app! Download it here: [Your App Link]",
            subject: Text("Check out this app!"),
            message: Text("I think you'll love using this app.")
        ) {
            Label("Refer Friends", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.secondary)
    }
}

// MARK: - Supporting Views
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search by name or phone number", text: $text)
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

struct SearchResultRow: View {
    let user: UserProfile
    let contactsViewModel: ContactsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                Text(user.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            switch user.friendshipStatus {
            case .none:
                Button("Add Friend") {
                    Task {
                        await contactsViewModel.sendFriendRequest(
                            toUserId: user.id,
                            toUserName: "\(user.firstName) \(user.lastName)"
                        )
                    }
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
            case .pending:
                Text("Pending")
                    .foregroundColor(.secondary)
                
            case .accepted:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
            case .declined:
                Button("Try Again") {
                    Task {
                        await contactsViewModel.sendFriendRequest(toUserId: user.id, toUserName: "\(user.firstName) \(user.lastName)")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct ContactsList: View {
    let contacts: [Contact]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contacts (\(contacts.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(contacts) { contact in
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(contact.name)
                            if contact.isAppUser {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Text(contact.phoneNumber ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !contact.isAppUser {
                        Button("Invite") {
                            // Handle invite action
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FriendRequestCard: View {
    let request: Notification
    let contactsViewModel: ContactsViewModel
    let notificationsViewModel: NotificationsViewModel
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(request.fromUserName)
                .font(.headline)
            
            Text("Sent you a friend request")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                if isLoading {
                    ProgressView()
                        .padding(.horizontal)
                } else {
                    Button("Accept") {
                        Task {
                            isLoading = true
                            await contactsViewModel.acceptFriendRequest(request.fromUserId)
                            await notificationsViewModel.markAsRead(request.id)
                            isLoading = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    
                    Button("Decline") {
                        Task {
                            isLoading = true
                            await contactsViewModel.declineFriendRequest(request.fromUserId)
                            await notificationsViewModel.markAsRead(request.id)
                            isLoading = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
} 
