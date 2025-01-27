import SwiftUI

struct SplashScreen: View {
    let onSplashScreenFinish: () -> Void
    
    @State private var startAnimation = false 
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient 
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.9),
                        Color.accentColor.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 16) {
                    CrossView()
                        .frame(width: 150, height: 150)
                        
                    Text(NSLocalizedString("ministry_name", comment: "Ministry name"))
                        .font(.system(size: 32, weight: .light))
                        .tracking(1)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    Text("Serving God by Serving Others")
                        .font(.system(size: 16))
                        .foregroundColor(.primary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .offset(y: offsetY)
                .opacity(startAnimation ? 1 : 0)
                .scaleEffect(startAnimation ? 1 : 0.5)
                .padding(.horizontal, 32)
                .padding(.vertical, 64)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0)) {
                startAnimation = true
            }
            
            // Start floating animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                offsetY = 10
            }
            
            // Handle navigation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onSplashScreenFinish()
            }
        }
    }
}

#Preview {
    SplashScreen(onSplashScreenFinish: {})
} 
