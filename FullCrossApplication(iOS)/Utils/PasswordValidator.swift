import Foundation

struct PasswordValidator {
    static func validatePassword(_ password: String) -> Bool {
        // At least 8 characters
        guard password.count >= 8 else { return false }
        
        // At least one uppercase letter
        guard password.contains(where: { $0.isUppercase }) else { return false }
        
        // At least one lowercase letter
        guard password.contains(where: { $0.isLowercase }) else { return false }
        
        // At least one number
        guard password.contains(where: { $0.isNumber }) else { return false }
        
        // At least one special character
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*(),.?\":{}|<>")
        guard password.unicodeScalars.contains(where: { specialCharacters.contains($0) }) else { return false }
        
        return true
    }
    
    static func getPasswordRequirementsMessage() -> String {
        """
        Password must contain:
        • At least 8 characters
        • At least one uppercase letter
        • At least one lowercase letter
        • At least one number
        • At least one special character
        """
    }
} 
