import SwiftUI

struct ToastView: View {
    let message: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.top, 16)
    }
} 
