//
//  FullCrossApplication_iOS_App.swift
//  FullCrossApplication(iOS)
//
//  Created by Titus Neyland on 1/26/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct FullCrossApplication_iOS_App: App {
    init() {
        // Configure Firebase when ready
        @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
        // Configure other services here
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
