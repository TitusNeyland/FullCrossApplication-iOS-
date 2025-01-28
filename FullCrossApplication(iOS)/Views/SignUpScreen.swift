import SwiftUI

struct SignUpScreen: View {
    let onSignUpSuccess: () -> Void
    let onBackToLogin: () -> Void
    
    @StateObject private var authViewModel = AuthViewModel()
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Text("Create Account")
                        .font(.system(size: 28, weight: .medium))
                        .padding(.bottom, 32)
                    
                    // First Name
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.givenName)
                        .autocapitalization(.words)
                        .onChange(of: firstName) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Last Name
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                        .onChange(of: lastName) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Email
                    TextField("Email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .onChange(of: email) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: password) { _ in
                                authViewModel.clearError()
                            }
                        
                        Text(PasswordValidator.getPasswordRequirementsMessage())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                    
                    // Confirm Password
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onChange(of: confirmPassword) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Error Message
                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Sign Up Button
                    Button(action: {
                        if validateInputs() {
                            authViewModel.signUp(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                password: password,
                                roles: []
                            )
                        }
                    }) {
                        ZStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign Up")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(
                            isFormValid
                            ? Color.primary
                            : Color.primary.opacity(0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    // Back to Login
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.primary.opacity(0.8))
                        Button(action: onBackToLogin) {
                            Text("Log in")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(16)
                .frame(minHeight: geometry.size.height)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.9),
                        Color(.systemBackground).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .onChange(of: authViewModel.currentUser) { user in
            if user != nil {
                onSignUpSuccess()
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty
    }
    
    private func validateInputs() -> Bool {
        // Clear previous error
        authViewModel.clearError()
        
        // Validate first name
        if firstName.isEmpty {
            authViewModel.setError("First name cannot be empty")
            return false
        }
        
        if firstName.contains(" ") {
            authViewModel.setError("First name cannot contain spaces")
            return false
        }
        
        // Validate last name
        if lastName.isEmpty {
            authViewModel.setError("Last name cannot be empty")
            return false
        }
        
        if lastName.contains(" ") {
            authViewModel.setError("Last name cannot contain spaces")
            return false
        }
        
        // Validate email
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: email) {
            authViewModel.setError("Please enter a valid email address")
            return false
        }
        
        // Validate password
        if !PasswordValidator.validatePassword(password) {
            authViewModel.setError(PasswordValidator.getPasswordRequirementsMessage())
            return false
        }
        
        // Validate password confirmation
        if password != confirmPassword {
            authViewModel.setError("Passwords do not match")
            return false
        }
        
        return true
    }
}

#Preview {
    SignUpScreen(
        onSignUpSuccess: {},
        onBackToLogin: {}
    )
} 
