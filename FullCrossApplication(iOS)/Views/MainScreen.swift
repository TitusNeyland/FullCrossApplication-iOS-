import SwiftUI

struct MainScreen: View {
    let onSignOut: () -> Void
    
    @StateObject private var themeViewModel = ThemeViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab: BottomNavItem = .watch
    @State private var showContactSupport = false
    @State private var showHelpAndFaq = false
    @State private var showChangePassword = false
    @State private var showEditProfile = false
    @State private var showFriendsList = false
    
    private var availableTabs: [BottomNavItem] {
        if authViewModel.currentUser?.isAdmin == true {
            return BottomNavItem.allCases
        } else {
            return BottomNavItem.allCases.filter { $0 != .admin }
        }
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ForEach(availableTabs, id: \.self) { tab in
                    tabView(for: tab)
                        .tabItem {
                            Label(tab.title, systemImage: tab.icon)
                        }
                        .tag(tab)
                }
            }
        }
        .sheet(isPresented: $showContactSupport) {
            ContactSupportScreen()
        }
        .sheet(isPresented: $showHelpAndFaq) {
            HelpAndFaqScreen()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordScreen(onNavigateBack: {
                showChangePassword = false
            })
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileScreen(onNavigateBack: {
                showEditProfile = false
            })
        }
        .sheet(isPresented: $showFriendsList) {
            FriendsScreen(onNavigateBack: {
                showFriendsList = false
            })
        }
        .preferredColorScheme(themeViewModel.isDarkMode ? .dark : .light)
    }
    
    @ViewBuilder
    private func tabView(for tab: BottomNavItem) -> some View {
        NavigationView {
            switch tab {
            case .read:
                ReadScreen()
            case .notes:
                NotesScreen()
            case .watch:
                WatchScreen()
            case .donate:
                DonateScreen()
            case .account:
                AccountScreen(
                    onLogout: onSignOut,
                    onNavigateToSupport: { showContactSupport = true },
                    onNavigateToHelpAndFaq: { showHelpAndFaq = true },
                    onNavigateToChangePassword: { showChangePassword = true },
                    onNavigateToEditProfile: { showEditProfile = true },
                    onNavigateToFriends: { showFriendsList = true }
                )
                .navigationBarTitleDisplayMode(.inline)
            case .admin:
                AdminScreen()
            }
        }
    }
}

#Preview {
    MainScreen(onSignOut: {})
        .environmentObject(AuthViewModel())
} 