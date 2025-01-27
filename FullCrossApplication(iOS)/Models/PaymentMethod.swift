import SwiftUI

struct PaymentMethod: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let handle: String
    let description: String
    let deepLink: URL?
    let webLink: URL?
    
    static let allMethods: [PaymentMethod] = [
        PaymentMethod(
            name: "PayPal",
            iconName: "paypal.logo",  // You'll need to add these assets
            handle: "church@fullcrossministries.org",
            description: "Support our ministry securely through PayPal",
            deepLink: URL(string: "paypal://send/church@fullcrossministries.org"),
            webLink: URL(string: "https://paypal.me/fullcrossministries")
        ),
        PaymentMethod(
            name: "Cash App",
            iconName: "cashapp.logo",
            handle: "@FullCross",
            description: "Quick and easy donations with Cash App",
            deepLink: URL(string: "cashapp://cash.app/$FullCross"),
            webLink: URL(string: "https://cash.app/$FullCross")
        ),
        PaymentMethod(
            name: "Venmo",
            iconName: "venmo.logo",
            handle: "@Titus-Neyland",
            description: "Send your gift through Venmo",
            deepLink: URL(string: "venmo://paycharge?txn=pay&recipients=Titus-Neyland"),
            webLink: URL(string: "https://venmo.com/Titus-Neyland")
        ),
        PaymentMethod(
            name: "Zelle",
            iconName: "zelle.logo",
            handle: "donate@fullcross.org",
            description: "Direct bank transfer using Zelle",
            deepLink: nil,
            webLink: nil
        ),
        PaymentMethod(
            name: "Apple Pay",
            iconName: "apple.logo",
            handle: "donate@fullcross.org",
            description: "Quick and secure Apple Pay donation",
            deepLink: nil,
            webLink: nil
        ),
        PaymentMethod(
            name: "Givelify",
            iconName: "givelify.logo",
            handle: "Full Cross Ministries",
            description: "Support us through the Givelify platform",
            deepLink: URL(string: "givelify://donate/MTUxNDM5OQ==/selection"),
            webLink: URL(string: "https://www.givelify.com/donate/MTUxNDM5OQ==/selection")
        )
    ]
} 