import Foundation

struct FaqItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let category: String
    
    static let allItems = [
        // Notes & Discussions
        FaqItem(
            question: "How do I add a new note?",
            answer: "To add a new note, go to the Notes screen and tap the '+' icon in the top right corner. Fill in the title, content, and optionally add a verse reference and select a note type (General, Verse, or Sermon).",
            category: "Notes & Discussions"
        ),
        FaqItem(
            question: "What are the different types of notes?",
            answer: "There are three types of notes:\n• General: For everyday thoughts and reflections\n• Verse: Specifically for Bible verse reflections\n• Sermon: For notes taken during sermons",
            category: "Notes & Discussions"
        ),
        FaqItem(
            question: "How do I start a discussion?",
            answer: "Go to the Notes screen, switch to the Discussions tab, and tap the '+' icon. Enter a title and your thoughts to start a conversation with the community.",
            category: "Notes & Discussions"
        ),
        FaqItem(
            question: "Can I delete my notes or discussions?",
            answer: "Yes, you can delete any note or discussion you've created by tapping the trash icon. You'll be asked to confirm before permanent deletion.",
            category: "Notes & Discussions"
        ),
        
        // Bible Reading
        FaqItem(
            question: "How do I read the Bible?",
            answer: "Navigate to the Read screen and:\n1. Select your preferred Bible version\n2. Choose a book from the Old or New Testament\n3. Select a chapter to start reading\n4. Use the arrow buttons to navigate between chapters",
            category: "Bible Reading"
        ),
        FaqItem(
            question: "Can I add notes while reading the Bible?",
            answer: "Yes! While reading, tap on any verse to highlight it, then tap the note icon to add a verse-specific note. These notes will be linked to the verse reference.",
            category: "Bible Reading"
        ),
        FaqItem(
            question: "How do I find specific verses?",
            answer: "Use the search bar at the top of the Read screen to search for specific words, phrases, or verse references (e.g., 'John 3:16').",
            category: "Bible Reading"
        ),
        
        // Watch & Stream
        FaqItem(
            question: "How do I watch live services?",
            answer: "Go to the Watch screen to view current and upcoming live streams. During service times, you'll see a 'Watch Live' button to join the stream.",
            category: "Watch & Stream"
        ),
        FaqItem(
            question: "Can I watch previous services?",
            answer: "Yes! On the Watch screen, scroll down to find the 'Previous Streams' section where you can access recordings of past services.",
            category: "Watch & Stream"
        ),
        FaqItem(
            question: "How do I set reminders for services?",
            answer: "On any upcoming service, tap the bell icon to add a reminder to your calendar. You'll need to grant calendar permissions when first using this feature.",
            category: "Watch & Stream"
        ),
        
        // Social Features
        FaqItem(
            question: "How do I connect with friends?",
            answer: "Tap the people icon in the Watch screen to access social features. You can search for friends, send connection requests, and manage your connections.",
            category: "Social Features"
        ),
        FaqItem(
            question: "How do I join watch parties?",
            answer: "When watching a service, you can create or join a watch party to view together with friends. Look for the 'Watch Together' option in the stream view.",
            category: "Social Features"
        ),
        
        // Account & Settings
        FaqItem(
            question: "How do I change my password?",
            answer: "Go to the Account screen, tap on 'Change Password', enter your current password and your new password twice to confirm the change.",
            category: "Account & Settings"
        ),
        FaqItem(
            question: "How do I enable notifications?",
            answer: "In the Account screen, find the Notifications section. Toggle on the types of notifications you'd like to receive (services, friend requests, discussions, etc.).",
            category: "Account & Settings"
        ),
        FaqItem(
            question: "Can I customize my profile?",
            answer: "Yes! In the Account screen, tap on your profile to edit your name, add a profile picture, and update your personal information.",
            category: "Account & Settings"
        ),
        
        // Donations
        FaqItem(
            question: "How do I make a donation?",
            answer: "Go to the Donate screen where you'll find multiple payment options including:\n• PayPal\n• Cash App\n• Venmo\n• Credit/Debit Card\nChoose your preferred method and follow the instructions.",
            category: "Donations"
        ),
//        FaqItem(
//            question: "Are donations tax-deductible?",
//            answer: "Yes, all donations are tax-deductible. You can access your donation history and tax receipts from the Donate screen.",
//            category: "Donations"
//        ),
        FaqItem(
            question: "How do I contact support?",
            answer: "Go to the Account screen and tap 'Contact Support'. You can reach us through email, phone, or send a direct message through the app.",
            category: "Support"
        )
    ]
} 
