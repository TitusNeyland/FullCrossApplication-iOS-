import SwiftUI

struct PaymentMethod: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let handle: String
    let description: String
    let deepLink: URL?
    let webLink: URL?
    
    var logoName: String {
        switch name.lowercased() {
        case "paypal":
            return "paypal.logo"
        case "cash app":
            return "cashapp.logo"
        case "venmo":
            return "venmo.logo"
        case "zelle":
            return "zelle.logo"
        case "apple pay":
            return "apple.logo"
        case "givelify":
            return "givelify.logo"
        default:
            return "dollarsign.circle.fill" // System fallback icon
        }
    }

    static let allMethods: [PaymentMethod] = [
        PaymentMethod(
            name: "PayPal",
            iconName: "paypal.logo",  // Using the asset name
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
            handle: "@FullCross",
            description: "Send your gift through Venmo",
            deepLink: URL(string: "venmo://paycharge?txn=pay&recipients=Titus-Neyland"),
            webLink: URL(string: "https://venmo.com/Titus-Neyland")
        ),
//        PaymentMethod(
//            name: "Zelle",
//            iconName: "zelle.logo",
//            handle: "donate@fullcross.org",
//            description: "Direct bank transfer using Zelle",
//            deepLink: nil,
//            webLink: nil
//        ),
//        PaymentMethod(
//            name: "Apple Pay",
//            iconName: "apple.logo",
//            handle: "donate@fullcross.org",
//            description: "Quick and secure Apple Pay donation",
//            deepLink: nil,
//            webLink: nil
//        ),
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
