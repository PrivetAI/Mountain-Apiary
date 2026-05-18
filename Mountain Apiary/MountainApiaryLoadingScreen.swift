import SwiftUI

struct MountainApiaryLoadingScreen: View {
    @State private var pulse: CGFloat = 0.6

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ApiaryTheme.sand, ApiaryTheme.cream],
                startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(ApiaryTheme.amber.opacity(0.35), lineWidth: 6)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: 0.35)
                        .stroke(ApiaryTheme.amber, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(Double(pulse) * 360))
                        .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                    HexShape()
                        .fill(ApiaryTheme.amber)
                        .frame(width: 56, height: 56)
                }
                Text("Mountain Apiary")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(ApiaryTheme.walnut)
                Text("Preparing the valley...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ApiaryTheme.walnut.opacity(0.7))
            }
        }
        .onAppear {
            pulse = 1.0
        }
    }
}
