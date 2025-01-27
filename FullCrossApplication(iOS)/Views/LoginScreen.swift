import SwiftUI

struct LoginScreen: View {
    let onLoginSuccess: () -> Void
    let onSignUpClick: () -> Void
    
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    // Cross and Title
                    CrossView()
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 16)
                    
                    Text(NSLocalizedString("ministry_name", comment: "Ministry name"))
                        .font(.system(size: 32, weight: .light))
                        .tracking(1)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .shadow(color: .accentColor.opacity(0.3), radius: 3, x: 2, y: 2)
                        .padding(.bottom, 32)
                    
                    // Error Message
                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .padding(.bottom, 16)
                    }
                    
                    // Login Fields
                    TextField("Email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .onChange(of: email) { _ in
                            authViewModel.clearError()
                        }
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onChange(of: password) { _ in
                            authViewModel.clearError()
                        }
                    
                    // Login Button
                    Button(action: {
                        authViewModel.signIn(email: email, password: password)
                    }) {
                        ZStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(
                            email.isEmpty || password.isEmpty || authViewModel.isLoading
                            ? Color.primary.opacity(0.3)
                            : Color.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.primary.opacity(0.8))
                        Button(action: onSignUpClick) {
                            Text("Sign Up")
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
                onLoginSuccess()
            }
        }
    }
}

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.5), lineWidth: 1)
            )
    }
}

#Preview {
    LoginScreen(
        onLoginSuccess: {},
        onSignUpClick: {}
    )
} 