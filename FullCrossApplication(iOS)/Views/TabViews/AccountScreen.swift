import SwiftUI
import PhotosUI

struct AccountScreen: View {
    let onLogout: () -> Void
    let onNavigateToSupport: () -> Void
    let onNavigateToHelpAndFaq: () -> Void
    let onNavigateToChangePassword: () -> Void
    let onNavigateToEditProfile: () -> Void
    let onNavigateToFriends: () -> Void
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.themeViewModel) private var themeViewModel
    @StateObject private var notificationsViewModel = NotificationsViewModel()
    @StateObject private var contactsViewModel: ContactsViewModel
    
    @State private var showLogoutDialog = false
    @State private var showNotificationDialog = false
    @State private var showFriendsList = false
    @State private var notificationsEnabled = false
    
    init(
        onLogout: @escaping () -> Void,
        onNavigateToSupport: @escaping () -> Void,
        onNavigateToHelpAndFaq: @escaping () -> Void,
        onNavigateToChangePassword: @escaping () -> Void,
        onNavigateToEditProfile: @escaping () -> Void,
        onNavigateToFriends: @escaping () -> Void
    ) {
        self.onLogout = onLogout
        self.onNavigateToSupport = onNavigateToSupport
        self.onNavigateToHelpAndFaq = onNavigateToHelpAndFaq
        self.onNavigateToChangePassword = onNavigateToChangePassword
        self.onNavigateToEditProfile = onNavigateToEditProfile
        self.onNavigateToFriends = onNavigateToFriends
        _contactsViewModel = StateObject(wrappedValue: ContactsViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profile Card
                profileCard
                
                // Friends Card
                friendsCard
                
                Divider()
                    .padding(.vertical, 8)
                
                // Account Settings Section
                settingsSection(title: "Account Settings") {
                    settingsRow(icon: "pencil", title: "Edit Profile", action: onNavigateToEditProfile)
                    settingsRow(icon: "lock", title: "Change Password", action: onNavigateToChangePassword)
                    notificationRow
                }
                
                // App Settings Section
                appSettingsSection
                
                // Support Section
                settingsSection(title: "Support") {
                    settingsRow(icon: "questionmark.circle", title: "Help & FAQ", action: onNavigateToHelpAndFaq)
                    settingsRow(icon: "envelope", title: "Contact Support", action: onNavigateToSupport)
                }
                
                // Logout Button
                Button(role: .destructive, action: { showLogoutDialog = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                
                // Manage Friends Button
                Button(action: { showFriendsList = true }) {
                    HStack {
                        Image(systemName: "person.2")
                        Text("Manage Friends")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("Account")
        .confirmationDialog("Logout", isPresented: $showLogoutDialog) {
            Button("Logout", role: .destructive) {
                onLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to logout?")
        }
        .sheet(isPresented: $showFriendsList) {
            FriendsList(contactsViewModel: contactsViewModel) {
                showFriendsList = false
            }
        }
        .alert("Notification Settings", isPresented: $showNotificationDialog) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To receive notifications, please enable them in your device settings.")
        }
        .onAppear {
            authViewModel.fetchFriendsCount()
        }
    }
    
    // MARK: - Private Views
    private var profileCard: some View {
        VStack(spacing: 16) {
            ProfileImagePicker(
                imageData: authViewModel.profileImage,
                onImageSelected: { image in
                    authViewModel.updateProfileImage(image)
                }
            )
            
            VStack(spacing: 4) {
                Text("\(authViewModel.currentUser?.firstName ?? "") \(authViewModel.currentUser?.lastName ?? "")")
                    .font(.headline)
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var friendsCard: some View {
        Button(action: onNavigateToFriends) {
            HStack {
                HStack {
                    Image(systemName: "person.2")
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Friends")
                            .font(.headline)
                        Text("\(authViewModel.friendsCount) friends")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    private func settingsRow(
        icon: String,
        title: String,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: action ?? {}) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var notificationRow: some View {
        HStack {
            Image(systemName: "bell")
                .frame(width: 24)
            Text("Notifications")
            Spacer()
            Toggle("", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { newValue in
                    showNotificationDialog = true
                }
        }
        .padding()
    }
    
    private var darkModeRow: some View {
        HStack {
            Image(systemName: "moon.fill")
                .frame(width: 24)
                .foregroundColor(.primary)
            
            Text("Dark Mode")
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { themeViewModel.isDarkMode },
                set: { _ in themeViewModel.toggleDarkMode() }
            ))
            .tint(.green)  // This matches your Material Green color
            .toggleStyle(SwitchToggleStyle(tint: Color(red: 76/255, green: 175/255, blue: 80/255))) // RGB for Material Green 500
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Settings")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.vertical, 8)
            
            darkModeRow
            
            settingsRow(icon: "globe", title: "Language")
        }
        .padding(.horizontal)
    }
}

// MARK: - Profile Image Picker
struct ProfileImagePicker: View {
    let imageData: UIImage?
    let onImageSelected: (UIImage) -> Void
    
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                if let image = imageData {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 2))
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.secondary)
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .offset(x: 8, y: 2)
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImageSelected(image)
                }
            }
        }
    }
}

// MARK: - Friends List
struct FriendsList: View {
    let contactsViewModel: ContactsViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contactsViewModel.friends) { friend in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(friend.fullName)
                                .font(.headline)
                            Text(friend.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                // Implement remove friend functionality
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AccountScreen(
            onLogout: {},
            onNavigateToSupport: {},
            onNavigateToHelpAndFaq: {},
            onNavigateToChangePassword: {},
            onNavigateToEditProfile: {},
            onNavigateToFriends: {}
        )
    }
} 
