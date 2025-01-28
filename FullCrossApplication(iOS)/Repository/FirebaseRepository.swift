import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseRepository {
    private let db = Firestore.firestore()
    
    func getCurrentUser() async throws -> FCUser? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        
        let userDoc = try await db.collection("users")
            .document(firebaseUser.uid)
            .getDocument()
        
        guard userDoc.exists else { return nil }
        
        return FCUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            roles: Set(userDoc.get("roles") as? [String] ?? [])
        )
    }
    
    func signUp(firstName: String, lastName: String, email: String, password: String, roles: [String] = []) async throws -> FCUser {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "roles": roles,
            "createdAt": Timestamp()
        ]
        
        try await db.collection("users")
            .document(authResult.user.uid)
            .setData(userData)
        
        return FCUser(
            id: authResult.user.uid,
            email: email,
            roles: Set(roles)
        )
    }
    
    func signIn(email: String, password: String) async throws -> FCUser {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return try await getCurrentUser() ?? FCUser(
            id: authResult.user.uid,
            email: email,
            roles: []
        )
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = Auth.auth().currentUser?.email else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        // Reauthenticate user
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await Auth.auth().currentUser?.reauthenticate(with: credential)
        
        // Change password
        try await Auth.auth().currentUser?.updatePassword(to: newPassword)
    }
    
    func updateUserProfile(firstName: String, lastName: String, phoneNumber: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        try await db.collection("users")
            .document(userId)
            .updateData([
                "firstName": firstName,
                "lastName": lastName,
                "phoneNumber": phoneNumber
            ])
    }
} 