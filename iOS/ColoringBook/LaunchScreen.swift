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

/// Reusable app icon view - can be used for launch screen and icon generation
struct AppIconView: View {
    let size: CGFloat
    var showBackground: Bool = true

    var body: some View {
        ZStack {
            // Background
            if showBackground {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.35, blue: 0.9),
                                Color(red: 0.45, green: 0.25, blue: 0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
            }

            // Coloring page representation
            RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                .fill(.white)
                .frame(width: size * 0.55, height: size * 0.65)
                .offset(x: -size * 0.05, y: size * 0.02)
                .shadow(color: .black.opacity(0.15), radius: size * 0.03, y: size * 0.02)

            // Simple star/flower drawing on the page
            StarShape()
                .stroke(Color(red: 0.3, green: 0.3, blue: 0.3), lineWidth: size * 0.02)
                .frame(width: size * 0.25, height: size * 0.25)
                .offset(x: -size * 0.05, y: size * 0.02)

            // Crayon/pencil
            CrayonShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.7, blue: 0.2),
                            Color(red: 0.95, green: 0.55, blue: 0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.12, height: size * 0.45)
                .rotationEffect(.degrees(35))
                .offset(x: size * 0.22, y: size * 0.1)
                .shadow(color: .black.opacity(0.2), radius: size * 0.02, y: size * 0.01)
        }
        .frame(width: size, height: size)
    }
}

/// Simple star shape for the icon
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5

        var path = Path()

        for i in 0..<points * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2

            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// Crayon/pencil shape for the icon
struct CrayonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tipHeight = rect.height * 0.2

        // Pencil body
        path.move(to: CGPoint(x: 0, y: tipHeight))
        path.addLine(to: CGPoint(x: rect.width, y: tipHeight))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        // Pencil tip
        path.move(to: CGPoint(x: 0, y: tipHeight))
        path.addLine(to: CGPoint(x: rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: tipHeight))
        path.closeSubpath()

        return path
    }
}

#Preview("Launch Screen") {
    LaunchScreen()
}

#Preview("App Icon") {
    AppIconView(size: 200)
        .padding(50)
        .background(Color.gray.opacity(0.2))
}
