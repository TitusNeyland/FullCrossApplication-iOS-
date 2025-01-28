struct PasswordValidator {
    static func validatePassword(_ password: String) -> Bool {
        let minLength = 8
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[@$!%*?&#]", options: .regularExpression) != nil
        
        return password.count >= minLength &&
            hasUppercase &&
            hasLowercase &&
            hasDigit &&
            hasSpecialChar
    }
    
    static func getPasswordRequirementsMessage() -> String {
        return "Password must contain at least:\n" +
            "• 8 characters\n" +
            "• One uppercase letter\n" +
            "• One lowercase letter\n" +
            "• One number\n" +
            "• One special character (@$!%*?&#)"
    }
} 
