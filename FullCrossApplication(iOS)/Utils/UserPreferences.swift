import Foundation
import Combine

class UserPreferences {
    static let shared = UserPreferences()
    private let defaults = UserDefaults.standard
    
    @Published var isDarkMode: Bool {
        didSet {
            defaults.set(isDarkMode, forKey: "is_dark_mode")
        }
    }
    
    private init() {
        self.isDarkMode = defaults.bool(forKey: "is_dark_mode")
    }
    
    func setDarkMode(_ isDarkMode: Bool) {
        self.isDarkMode = isDarkMode
    }
    
    var darkModePublisher: AnyPublisher<Bool, Never> {
        $isDarkMode.eraseToAnyPublisher()
    }
} 