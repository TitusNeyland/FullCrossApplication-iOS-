import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var error: String?
    @Published var isLoading = false
    
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil
        
        // TODO: Implement actual authentication logic here
        // For now, simulating network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            // Simulate success
            if email == "test@test.com" && password == "password" {
                self.currentUser = User(id: "1", email: email, roles: ["user"])
            } else {
                self.error = "Invalid email or password"
            }
        }
    }
    
    func signUp(email: String, password: String, firstName: String, lastName: String) {
        isLoading = true
        error = nil
        
        // TODO: Implement actual sign up logic here
        // For now, simulating network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            // Simulate success
            self.currentUser = User(id: UUID().uuidString, email: email, roles: ["user"])
        }
    }
    
    func setError(_ message: String) {
        error = message
    }
    
    func clearError() {
        error = nil
    }
    
    func signOut() {
        // TODO: Implement actual sign out logic here
        currentUser = nil
    }
}

struct User: Equatable {
    let id: String
    let email: String
    let roles: Set<String>
    
    var isAdmin: Bool {
        roles.contains("admin")
    }
} 