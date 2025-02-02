import SwiftUI
import Combine

class ThemeViewModel: ObservableObject {
    @Published var isDarkMode: Bool = false
    private let userPreferences = UserPreferences.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to changes from UserPreferences
        userPreferences.darkModePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.isDarkMode = newValue
                self?.applyTheme()
            }
            .store(in: &cancellables)
        
        // Initialize with current value
        isDarkMode = userPreferences.isDarkMode
        applyTheme()
    }
    
    func toggleDarkMode() {
        userPreferences.setDarkMode(!isDarkMode)
    }
    
    private func applyTheme() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
                }
            }
        }
    }
}

// MARK: - Environment Key
private struct ThemeViewModelKey: EnvironmentKey {
    static let defaultValue = ThemeViewModel()
}

extension EnvironmentValues {
    var themeViewModel: ThemeViewModel {
        get { self[ThemeViewModelKey.self] }
        set { self[ThemeViewModelKey.self] = newValue }
    }
} 