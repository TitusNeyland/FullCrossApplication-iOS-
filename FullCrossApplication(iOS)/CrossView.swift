import SwiftUI

struct CrossView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vertical line
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 4)
                    .frame(height: 130)
                    .frame(maxHeight: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Horizontal line
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 4)
                    .frame(width: 100)
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.4)
            }
        }
    }
}

#Preview {
    CrossView()
        .frame(width: 150, height: 150)
} 
