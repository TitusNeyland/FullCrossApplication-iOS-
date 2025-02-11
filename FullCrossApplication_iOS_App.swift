// Add UNUserNotificationCenterDelegate to your AppDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Keep any existing setup code...
        
        // Setup notifications
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound when notification is received in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification response when user taps the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "service":
                // Handle service notification tap
                NotificationCenter.default.post(name: .serviceNotificationTapped, object: nil)
            case "discussion":
                // Handle discussion notification tap
                NotificationCenter.default.post(name: .discussionNotificationTapped, object: nil)
            case "friend_request":
                // Handle friend request notification tap
                NotificationCenter.default.post(name: .friendRequestNotificationTapped, object: nil)
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    // Handle registration for remote notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        // Here you would typically send this token to your server
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// Add these notification names
extension Notification.Name {
    static let serviceNotificationTapped = Notification.Name("serviceNotificationTapped")
    static let discussionNotificationTapped = Notification.Name("discussionNotificationTapped")
    static let friendRequestNotificationTapped = Notification.Name("friendRequestNotificationTapped")
} 