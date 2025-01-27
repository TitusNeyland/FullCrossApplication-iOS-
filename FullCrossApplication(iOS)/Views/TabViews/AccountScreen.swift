import SwiftUI

struct AccountScreen: View {
    let onLogout: () -> Void
    let onNavigateToSupport: () -> Void
    let onNavigateToHelpAndFaq: () -> Void
    let onNavigateToChangePassword: () -> Void
    let onNavigateToEditProfile: () -> Void
    let onNavigateToFriends: () -> Void
    
    var body: some View {
        List {
            Section {
                Button("Edit Profile") {
                    onNavigateToEditProfile()
                }
                Button("Change Password") {
                    onNavigateToChangePassword()
                }
                Button("Friends") {
                    onNavigateToFriends()
                }
            }
            
            Section {
                Button("Help & FAQ") {
                    onNavigateToHelpAndFaq()
                }
                Button("Contact Support") {
                    onNavigateToSupport()
                }
            }
            
            Section {
                Button(role: .destructive, action: onLogout) {
                    Text("Sign Out")
                }
            }
        }
        .navigationTitle("Account")
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