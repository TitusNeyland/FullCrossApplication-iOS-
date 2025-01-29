import SwiftUI
import Combine

class ThemeViewModel: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load saved dark mode preference, default to system setting if not set
        self.isDarkMode = userDefaults.object(forKey: "isDarkMode") as? Bool ?? false
        
        // Listen for changes to system dark mode setting
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkSystemDarkMode()
            }
            .store(in: &cancellables)
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
    }
    
    private func checkSystemDarkMode() {
        // If no user preference is set, follow system
        if userDefaults.object(forKey: "isDarkMode") == nil {
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
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