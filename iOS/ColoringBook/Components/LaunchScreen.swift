import SwiftUI

/// Launch screen shown while app loads
struct LaunchScreen: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.3, blue: 0.85),
                    Color(red: 0.4, green: 0.2, blue: 0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Icon
                AppIconView(size: 120)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

                // App name
                Text("Coloring Book")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview("Launch Screen") {
    LaunchScreen()
}
