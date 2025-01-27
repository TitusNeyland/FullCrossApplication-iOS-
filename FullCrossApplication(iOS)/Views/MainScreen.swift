import SwiftUI

struct MainScreen: View {
    let onSignOut: () -> Void
    @StateObject private var themeViewModel = ThemeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Full Cross Ministries!")
                    .font(.title2)
                    .padding()
                
                Spacer()
                
                // Main content here
                Text("Main content coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Full Cross")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            themeViewModel.toggleTheme()
                        }) {
                            Label(
                                themeViewModel.isDarkMode ? "Light Mode" : "Dark Mode",
                                systemImage: themeViewModel.isDarkMode ? "sun.max.fill" : "moon.fill"
                            )
                        }
                        
                        Button(role: .destructive, action: onSignOut) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                }
            }
        }
        .preferredColorScheme(themeViewModel.isDarkMode ? .dark : .light)
    }
}

#Preview {
    MainScreen(onSignOut: {})
} 