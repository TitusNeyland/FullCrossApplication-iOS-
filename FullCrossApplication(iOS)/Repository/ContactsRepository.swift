import Foundation
import Contacts
import FirebaseFirestore
import Combine

protocol ContactsRepository {
    func getContacts() async throws -> [Contact]
    func getAppUsers() async throws -> Set<String>
}

class ContactsRepositoryImpl: ContactsRepository {
    private let db = Firestore.firestore()
    private let store = CNContactStore()
    
    func getContacts() async throws -> [Contact] {
        // Request permission
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authStatus == .notDetermined {
            let granted = try await store.requestAccess(for: .contacts)
            if !granted {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Contact access denied"])
            }
        } else if authStatus == .denied {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Contact access denied. Please enable in Settings."])
        }
        
        // Fetch contacts
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        var contacts: [Contact] = []
        try store.enumerateContacts(with: request) { contact, _ in
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            if !name.isEmpty, let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                contacts.append(Contact(
                    id: UUID().uuidString,
                    name: name,
                    phoneNumber: phoneNumber,
                    isAppUser: false
                ))
            }
        }
        
        return contacts.sorted { $0.name < $1.name }
    }
    
    func getAppUsers() async throws -> Set<String> {
        let snapshot = try await db.collection("users").getDocuments()
        return Set(snapshot.documents.compactMap { doc -> String? in
            guard let phoneNumber = doc.get("phoneNumber") as? String else { return nil }
            return phoneNumber.replacingOccurrences(of: "[^0-9]", with: "")
        })
    }
} 