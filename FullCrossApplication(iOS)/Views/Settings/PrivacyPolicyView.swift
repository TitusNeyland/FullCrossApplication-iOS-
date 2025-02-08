import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Introduction
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                
                Text("Last updated: \(formattedDate)")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                // Information We Collect
                PolicySection(title: "Information We Collect") {
                    Text("We collect the following information to provide and improve our services:")
                    
                    BulletPoint("Name and profile information")
                    BulletPoint("Email address")
                    BulletPoint("Phone number")
                    BulletPoint("Profile picture (when provided)")
                    BulletPoint("Friend connections within the app")
                    BulletPoint("Notes and discussions you create")
                }
                
                // Device Permissions
                PolicySection(title: "Device Permissions") {
                    Text("Our app requests access to:")
                    
                    BulletPoint("Camera Roll: To select and upload profile pictures")
                    BulletPoint("Calendar: To add church service reminders")
                    BulletPoint("Notifications: To send important updates and reminders")
                }
                
                // How We Use Your Information
                PolicySection(title: "How We Use Your Information") {
                    Text("We use your information to:")
                    
                    BulletPoint("Create and manage your account")
                    BulletPoint("Connect you with other church members")
                    BulletPoint("Send service reminders and notifications")
                    BulletPoint("Provide access to live streams and recorded services")
                    BulletPoint("Store and manage your personal notes and discussions")
                }
                
                // Data Storage
                PolicySection(title: "Data Storage") {
                    Text("Your data is securely stored using Firebase, with the following measures:")
                    
                    BulletPoint("Encrypted data transmission")
                    BulletPoint("Secure cloud storage")
                    BulletPoint("Regular security updates")
                    BulletPoint("Access controls and authentication")
                }
                
                // Data Sharing
                PolicySection(title: "Data Sharing") {
                    Text("We do not sell or share your personal information with third parties. Your information is only visible to:")
                    
                    BulletPoint("Church administrators (basic profile information)")
                    BulletPoint("Friends you connect with (based on your privacy settings)")
                    BulletPoint("Other members in discussion threads you participate in")
                }
                
                // Legal Basis for Processing
                PolicySection(title: "Legal Basis for Processing") {
                    Text("We process your personal information based on:")
                    
                    BulletPoint("Your consent when you create an account")
                    BulletPoint("Contractual necessity to provide our services")
                    BulletPoint("Legitimate interests in improving our services")
                    BulletPoint("Legal obligations for record keeping")
                }
                
                // Third-Party Services
                PolicySection(title: "Third-Party Services") {
                    Text("We use the following third-party services:")
                    
                    BulletPoint("Firebase (Google Cloud) for secure data storage and authentication")
                    BulletPoint("Apple Push Notification service for notifications")
                    BulletPoint("Facebook API for live streaming integration")
                    
                    Text("These services may collect and process your data according to their own privacy policies.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                
                // Data Retention
                PolicySection(title: "Data Retention") {
                    Text("We retain your data as follows:")
                    
                    BulletPoint("Account information: As long as your account is active")
                    BulletPoint("Notes and discussions: Until manually deleted by you")
                    BulletPoint("Usage data: Up to 24 months")
                    BulletPoint("Inactive accounts: Deleted after 24 months of inactivity")
                }
                
                // Children's Privacy
                PolicySection(title: "Children's Privacy") {
                    Text("Our service is not directed to children under 13. We do not knowingly collect personal information from children under 13. If you are a parent/guardian and believe your child has provided us with personal information, please contact us.")
                        .padding(.bottom, 8)
                    
                    Text("Users between 13-16 years old require parental consent to create an account.")
                }
                
                // Dispute Resolution
                PolicySection(title: "Dispute Resolution") {
                    Text("Any disputes regarding this privacy policy will be:")
                    
                    BulletPoint("First addressed through informal resolution")
                    BulletPoint("Subject to the laws of the State of Texas")
                    BulletPoint("Resolved through mediation if informal resolution fails")
                    BulletPoint("Finally settled through arbitration if necessary")
                }
                
                // Updates to Policy
                PolicySection(title: "Updates to Privacy Policy") {
                    Text("We may update this privacy policy from time to time. We will notify you of any changes by:")
                    
                    BulletPoint("Posting the new policy in the app")
                    BulletPoint("Sending you an email notification")
                    BulletPoint("Requiring renewed consent if necessary")
                }
                
                // Your Rights
                PolicySection(title: "Your Rights") {
                    Text("You have the right to:")
                    
                    BulletPoint("Access your personal information")
                    BulletPoint("Update or correct your information")
                    BulletPoint("Delete your account and associated data")
                    BulletPoint("Opt-out of notifications")
                    BulletPoint("Control your privacy settings")
                }
                
                // Contact Information
                PolicySection(title: "Contact Us") {
                    Text("If you have questions about this privacy policy or your data, please contact us at:")
                    Text("privacy@crosschurch.com")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: Date())
    }
}

// Helper Views
private struct PolicySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            content()
        }
        .padding(.bottom, 20)
    }
}

private struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .padding(.leading)
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
} 