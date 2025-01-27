import Foundation

struct FaqItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let category: String
    
    static let allItems = [
        FaqItem(
            question: "How do I add a new note?",
            answer: "To add a new note, go to the Notes screen and tap the '+' icon in the top right corner. Fill in the title, content, and optionally add a verse reference and select a note type.",
            category: "Notes"
        ),
        FaqItem(
            question: "Can I delete my notes?",
            answer: "Yes, you can delete any note by opening it and tapping the delete (trash) icon. You'll be asked to confirm before the note is permanently deleted.",
            category: "Notes"
        ),
        FaqItem(
            question: "How do I read the Bible?",
            answer: "Navigate to the Read screen, select your preferred Bible version, choose a book, and then select a chapter to start reading. You can navigate between chapters using the arrow buttons.",
            category: "Bible Reading"
        ),
        FaqItem(
            question: "How do I make a donation?",
            answer: "Go to the Donate screen where you'll find multiple payment options including PayPal, Cash App, Venmo, and more. Choose your preferred method and follow the instructions.",
            category: "Donations"
        ),
        FaqItem(
            question: "How do I change my password?",
            answer: "Go to the Account screen, tap on 'Change Password', enter your current password and your new password twice to confirm the change.",
            category: "Account"
        ),
        FaqItem(
            question: "How do I enable notifications?",
            answer: "In the Account screen, find the Notifications toggle. If it's your first time, you'll be asked to grant permission. You can always adjust these settings later.",
            category: "Account"
        ),
        FaqItem(
            question: "What are note types used for?",
            answer: "Note types help organize your spiritual journey. You can categorize notes as General, Prayer, Sermon, or Study to better track different aspects of your faith journey.",
            category: "Notes"
        ),
        FaqItem(
            question: "How do I contact support?",
            answer: "Go to the Account screen and tap 'Contact Support'. You can reach us through email, phone, or send a direct message through the app.",
            category: "Support"
        )
    ]
} 