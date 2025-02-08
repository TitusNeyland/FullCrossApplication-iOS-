import SwiftUI

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack {
        MenuRow(
            icon: "lock.shield",
            title: "Privacy Policy",
            subtitle: "Learn how we protect your data"
        )
        MenuRow(
            icon: "gear",
            title: "Settings"
        )
    }
    .padding()
} 