import SwiftUI

struct NotificationPreferencesView: View {
    @ObservedObject var viewModel: NotificationsViewModel
    @AppStorage("notifyServices") private var notifyServices = true
    @AppStorage("notifyDiscussions") private var notifyDiscussions = true
    @AppStorage("notifyFriends") private var notifyFriends = true
    
    var body: some View {
        Form {
            Section(header: Text("Notify Me About")) {
                Toggle("Upcoming Services", isOn: $notifyServices)
                Toggle("New Discussion Responses", isOn: $notifyDiscussions)
                Toggle("Friend Requests", isOn: $notifyFriends)
            }
            
            Section(footer: Text("You can always change these settings later in your device's notification settings.")) {
                Button("Open System Settings") {
                    viewModel.openSettings()
                }
            }
        }
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
} 