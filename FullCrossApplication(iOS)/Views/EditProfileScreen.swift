import SwiftUI

struct EditProfileScreen: View {
    let onNavigateBack: () -> Void
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var showSuccessDialog = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.bottom)
                    }
                    
                    // First Name
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: firstName) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Last Name
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: lastName) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Phone Number
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                        .onChange(of: phoneNumber) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Email
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: email) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Save Button
                    Button {
                        if let validationError = validateInputs() {
                            authViewModel.setError(validationError)
                        } else {
                            authViewModel.updateProfile(
                                firstName: firstName,
                                lastName: lastName,
                                phoneNumber: phoneNumber,
                                email: email
                            ) { success in
                                if success {
                                    showSuccessDialog = true
                                }
                            }
                        }
                    } label: {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onNavigateBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .onAppear {
                // Initialize fields with current user data
                firstName = authViewModel.currentUser?.firstName ?? ""
                lastName = authViewModel.currentUser?.lastName ?? ""
                phoneNumber = authViewModel.currentUser?.phoneNumber ?? ""
                email = authViewModel.currentUser?.email ?? ""
            }
        }
        .alert("Success", isPresented: $showSuccessDialog) {
            Button("OK") {
                onNavigateBack()
            }
        } message: {
            Text("Your profile has been successfully updated.")
        }
    }
    
    private func validateInputs() -> String? {
        switch true {
        case firstName.isEmpty:
            return "First name cannot be empty"
        case lastName.isEmpty:
            return "Last name cannot be empty"
        case firstName.contains(" "):
            return "First name cannot contain spaces"
        case lastName.contains(" "):
            return "Last name cannot contain spaces"
        case email.contains(" "):
            return "Email cannot contain spaces"
        case !email.matches(pattern: "[a-zA-Z0-9._-]+@[a-z]+\\.+[a-z]+"):
            return "Please enter a valid email address"
        case phoneNumber.isEmpty:
            return "Phone number cannot be empty"
        default:
            return nil
        }
    }
}

// String extension for regex matching
extension String {
    func matches(pattern: String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview {
    EditProfileScreen(onNavigateBack: {})
        .environmentObject(AuthViewModel())
} 