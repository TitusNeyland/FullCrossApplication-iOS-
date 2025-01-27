//
//  ContentView.swift
//  FullCrossApplication(iOS)
//
//  Created by Titus Neyland on 1/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSplash = true
    
    var body: some View {
        Group {
            if showingSplash {
                SplashScreen {
                    withAnimation {
                        showingSplash = false
                    }
                }
            } else {
                // Your main app content here
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, world!")
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
