//
//  ContentView.swift
//  FullCrossApplication(iOS)
//
//  Created by Titus Neyland on 1/26/25.
//

import SwiftUI

enum Screen {
    case splash
    case login
    case signUp
    case main
}

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var currentScreen: Screen = .splash
    
    var body: some View {
        Group {
            switch currentScreen {
            case .splash:
                SplashScreen {
                    withAnimation {
                        currentScreen = authViewModel.currentUser != nil ? .main : .login
                    }
                }
                
            case .login:
                LoginScreen(
                    onLoginSuccess: {
                        withAnimation {
                            currentScreen = .main
                        }
                    },
                    onSignUpClick: {
                        withAnimation {
                            currentScreen = .signUp
                        }
                    }
                )
                
            case .signUp:
                SignUpScreen(
                    onSignUpSuccess: {
                        withAnimation {
                            currentScreen = .main
                        }
                    },
                    onBackToLogin: {
                        withAnimation {
                            currentScreen = .login
                        }
                    }
                )
                
            case .main:
                MainScreen(
                    onSignOut: {
                        authViewModel.signOut()
                        withAnimation {
                            currentScreen = .login
                        }
                    }
                )
            }
        }
        .environmentObject(authViewModel)
    }
}

#Preview {
    ContentView()
}
