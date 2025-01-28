import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published private(set) var currentUser: FCUser?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var friendsCount = 0
    @Published private(set) var profileImage: UIImage?
    
    private let repository: FirebaseRepository
    private let db = Firestore.firestore()
    
    init(repository: FirebaseRepository = FirebaseRepository()) {
        self.repository = repository
        Task {
            await checkCurrentUser()
        }
    }
    
    private func checkCurrentUser() async {
        do {
            currentUser = try await repository.getCurrentUser()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            isLoading = true
            error = nil
            
            do {
                currentUser = try await repository.signIn(email: email, password: password)
            } catch {
                self.error = "Invalid email or password. Please try again."
            }
            
            isLoading = false
        }
    }
    
    func signUp(firstName: String, lastName: String, email: String, password: String, roles: [String] = []) {
        Task {
            isLoading = true
            error = nil
            
            do {
                currentUser = try await repository.signUp(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    password: password,
                    roles: roles
                )
            } catch {
                self.error = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    func signOut() {
        repository.signOut()
        currentUser = nil
    }
    
    func clearError() {
        error = nil
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Bool) -> Void) {
        Task {
            isLoading = true
            error = nil
            
            do {
                try await repository.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                isLoading = false
                completion(true)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
                completion(false)
            }
        }
    }
    
    func setError(_ message: String) {
        error = message
    }
    
    func updateProfile(firstName: String, lastName: String, phoneNumber: String, email: String, completion: @escaping (Bool) -> Void) {
        Task {
            isLoading = true
            error = nil
            
            do {
                try await repository.updateUserProfile(
                    firstName: firstName,
                    lastName: lastName,
                    phoneNumber: phoneNumber
                )
                currentUser = try await repository.getCurrentUser()
                isLoading = false
                completion(true)
            } catch {
                self.error = error.localizedDescription
                isLoading = false
                completion(false)
            }
        }
    }
    
    func fetchFriendsCount() {
        Task {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            do {
                let snapshot = try await db.collection("users")
                    .document(userId)
                    .collection("friendships")
                    .whereField("status", isEqualTo: "accepted")
                    .getDocuments()
                
                friendsCount = snapshot.documents.count
            } catch {
                friendsCount = 0
            }
        }
    }
    
    // Note: Image upload functionality would need to be implemented with Firebase Storage
    func updateProfileImage(_ image: UIImage) {
        // TODO: Implement image upload to Firebase Storage
        profileImage = image
    }
} 