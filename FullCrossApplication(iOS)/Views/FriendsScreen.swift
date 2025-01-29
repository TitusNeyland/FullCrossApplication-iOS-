import SwiftUI

struct FriendsScreen: View {
    let onNavigateBack: () -> Void
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if viewModel.friends.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No friends yet")
                            .font(.title2)
                        
                        Text("Add friends to connect with them")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.friends) { friend in
                                FriendItemView(friend: friend, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onNavigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadFriends()
        }
    }
}

struct FriendItemView: View {
    let friend: UserProfile
    let viewModel: FriendsViewModel
    
    var body: some View {
        VStack {
            HStack {
                // Profile Icon
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Friend Info
                VStack(alignment: .leading) {
                    Text(friend.fullName)
                        .font(.headline)
                    Text(friend.phoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Friendship Status Actions
                switch friend.friendshipStatus {
                case .none:
                    Button("Add Friend") {
                        viewModel.sendFriendRequest(friend.id)
                    }
                case .pending:
                    HStack {
                        Button("Accept") {
                            viewModel.acceptFriendRequest(friend.id)
                        }
                        Button("Decline") {
                            viewModel.declineFriendRequest(friend.id)
                        }
                    }
                case .accepted:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .declined:
                    Button("Try Again") {
                        viewModel.sendFriendRequest(friend.id)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    FriendsScreen(onNavigateBack: {})
} 