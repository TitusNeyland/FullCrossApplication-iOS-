import SwiftUI
import MessageUI

struct ContactSupportScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var showingMailComposer = false
    @State private var showingMessageComposer = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 45) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("How can we help?")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Choose a method to get in touch with our support team")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Contact Methods
                    VStack(spacing: 12) {
                        ContactMethodCard(
                            title: "Email Support",
                            description: "Send us an email at titusaneyland@gmail.com",
                            systemImage: "envelope.fill"
                        ) {
                            if MFMailComposeViewController.canSendMail() {
                                showingMailComposer = true
                            } else {
                                guard let url = URL(string: "mailto:titusaneyland@gmail.com") else { return }
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        ContactMethodCard(
                            title: "Phone Support",
                            description: "Call us at (601) 954-9253",
                            systemImage: "phone.fill"
                        ) {
                            guard let url = URL(string: "tel:6019549253") else { return }
                            UIApplication.shared.open(url)
                        }
                        
                        ContactMethodCard(
                            title: "Live Chat",
                            description: "Chat with our support team",
                            systemImage: "message.fill"
                        ) {
                            // Implement live chat functionality
                        }
                    }
                    .padding(.horizontal)
                    
                    // Message Form
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Send us a message")
                            .font(.headline)
                        
                        TextEditor(text: $messageText)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Button(action: {
                            if MFMessageComposeViewController.canSendText() {
                                showingMessageComposer = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send Message")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(messageText.isEmpty)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView(
                    toRecipients: ["titusaneyland@gmail.com"],
                    subject: "Support Request",
                    messageBody: messageText,
                    completion: { _ in
                        showSuccessAlert = true
                        messageText = ""
                    }
                )
            }
            .sheet(isPresented: $showingMessageComposer) {
                MessageComposerView(
                    recipients: ["6019549253"],
                    body: messageText,
                    completion: { _ in
                        showSuccessAlert = true
                        messageText = ""
                    }
                )
            }
            .alert("Message Sent", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Thank you for your message. We'll get back to you soon!")
            }
        }
    }
}

// Mail Composer Wrapper
struct MailComposerView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let messageBody: String
    let completion: (MFMailComposeResult) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(toRecipients)
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let completion: (MFMailComposeResult) -> Void
        
        init(completion: @escaping (MFMailComposeResult) -> Void) {
            self.completion = completion
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.completion(result)
            }
        }
    }
}

// Message Composer Wrapper
struct MessageComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let completion: (MessageComposeResult) -> Void
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = context.coordinator
        composer.recipients = recipients
        composer.body = body
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let completion: (MessageComposeResult) -> Void
        
        init(completion: @escaping (MessageComposeResult) -> Void) {
            self.completion = completion
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) {
                self.completion(result)
            }
        }
    }
}

#Preview {
    ContactSupportScreen()
} 
