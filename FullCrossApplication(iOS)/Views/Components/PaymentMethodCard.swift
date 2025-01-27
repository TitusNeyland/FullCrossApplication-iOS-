import SwiftUI

struct PaymentMethodCard: View {
    let paymentMethod: PaymentMethod
    @State private var isLoading = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: handlePaymentTap) {
            HStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(paymentMethod.iconName)
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(paymentMethod.name)
                        .font(.headline)
                    
                    Text(paymentMethod.handle)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    
                    if !paymentMethod.description.isEmpty {
                        Text(paymentMethod.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Loading indicator or chevron
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(0.1),
                        radius: isPressed ? 4 : 1,
                        y: isPressed ? 2 : 1
                    )
            )
        }
        .buttonStyle(PaymentMethodButtonStyle())
    }
    
    private func handlePaymentTap() {
        guard !isLoading else { return }
        isLoading = true
        
        if let deepLink = paymentMethod.deepLink,
           UIApplication.shared.canOpenURL(deepLink) {
            UIApplication.shared.open(deepLink) { success in
                if !success, let webLink = paymentMethod.webLink {
                    UIApplication.shared.open(webLink)
                }
                isLoading = false
            }
        } else if let webLink = paymentMethod.webLink {
            UIApplication.shared.open(webLink) { _ in
                isLoading = false
            }
        } else {
            isLoading = false
        }
    }
}

struct PaymentMethodButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
} 