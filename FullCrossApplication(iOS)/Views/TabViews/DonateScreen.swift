import SwiftUI

struct DonateScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                    
                    Text("Support Our Ministry")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Your generous donations help us spread the Gospel and support our community. Every gift makes a difference.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)
                
                // Payment Methods Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ways to Give")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(PaymentMethod.allMethods) { method in
                            PaymentMethodCard(paymentMethod: method)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Scripture Quote Card
                VStack(spacing: 8) {
                    Text("\"For God loves a cheerful giver.\"")
                        .font(.body)
                        .italic()
                        .multilineTextAlignment(.center)
                    
                    Text("2 Corinthians 9:7")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                )
                .padding(.horizontal)
                
                Spacer(minLength: 24)
            }
        }
        .navigationTitle("")
    }
}

#Preview {
    NavigationView {
        DonateScreen()
    }
} 
