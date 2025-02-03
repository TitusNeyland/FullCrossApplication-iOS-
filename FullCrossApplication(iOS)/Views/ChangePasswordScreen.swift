import SwiftUI

struct ChangePasswordScreen: View {
    let onNavigateBack: () -> Void
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var showSuccessDialog = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Error message
                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.bottom)
                    }
                    
                    // Current password
                    SecureField("Current Password", text: $currentPassword)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: currentPassword) { _ in
                            authViewModel.clearError()
                        }
                    
                    // New password
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("New Password", text: $newPassword)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: newPassword) { _ in
                                authViewModel.clearError()
                            }
                        
                        Text(PasswordValidator.getPasswordRequirementsMessage())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Confirm new password
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: confirmNewPassword) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Change Password Button
                    Button {
                        if validatePasswords(newPassword: newPassword, confirmPassword: confirmNewPassword) {
                            authViewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword) { success in
                                if success {
                                    showSuccessDialog = true
                                }
                            }
                        } else {
                            authViewModel.setError("Please ensure your new password meets the requirements and matches the confirmation")
                        }
                    } label: {
                        Text("Change Password")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading || 
                            currentPassword.isEmpty || 
                            newPassword.isEmpty || 
                            confirmNewPassword.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Change Password")
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
        }
        .alert("Success", isPresented: $showSuccessDialog) {
            Button("OK") {
                onNavigateBack()
            }
        } message: {
            Text("Your password has been successfully changed.")
        }
    }
    
    private func validatePasswords(newPassword: String, confirmPassword: String) -> Bool {
        newPassword == confirmPassword && PasswordValidator.validatePassword(newPassword)
    }
}

#Preview {
    ChangePasswordScreen(onNavigateBack: {})
        .environmentObject(AuthViewModel())
} 