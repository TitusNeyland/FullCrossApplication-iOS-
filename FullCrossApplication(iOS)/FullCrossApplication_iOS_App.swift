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
    @StateObject private var themeViewModel = ThemeViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.themeViewModel, themeViewModel)
                .preferredColorScheme(themeViewModel.isDarkMode ? .dark : .light)
        }
    }
}
