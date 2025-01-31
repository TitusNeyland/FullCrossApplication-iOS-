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
        // Request contacts access if not already granted
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authStatus == .notDetermined {
            _ = try await store.requestAccess(for: .contacts)
        }
        
        guard authStatus == .authorized || authStatus == .notDetermined else {
            throw NSError(domain: "ContactsRepository",
                         code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Contacts access denied"])
        }
        
        // Fetch contacts
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ] as [CNKeyDescriptor]
        
        let containerId = store.defaultContainerIdentifier()
        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerId)
        
        let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        var uniqueContacts: [Contact] = []
        var seenPhoneNumbers = Set<String>()
        
        // Process contacts and remove duplicates
        for contact in contacts {
            guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else { continue }
            
            // Clean phone number format
            let cleanNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            
            // Skip if we've already seen this number
            if seenPhoneNumbers.contains(cleanNumber) { continue }
            seenPhoneNumbers.insert(cleanNumber)
            
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            if !name.isEmpty && !cleanNumber.isEmpty {
                uniqueContacts.append(Contact(
                    name: name,
                    phoneNumber: cleanNumber,
                    isAppUser: false
                ))
            }
        }
        
        // Update app user status
        let appUsers = try await getAppUsers()
        return uniqueContacts.map { contact in
            if let phone = contact.phoneNumber,
               appUsers.contains(phone.replacingOccurrences(of: "[^0-9]", with: "")) {
                return Contact(name: contact.name,
                             phoneNumber: contact.phoneNumber,
                             isAppUser: true)
            }
            return contact
        }
    }
    
    func getAppUsers() async throws -> Set<String> {
        let snapshot = try await db.collection("users").getDocuments()
        return Set(snapshot.documents.compactMap { doc -> String? in
            guard let phoneNumber = doc.get("phoneNumber") as? String else { return nil }
            return phoneNumber.replacingOccurrences(of: "[^0-9]", with: "")
        })
    }
} 