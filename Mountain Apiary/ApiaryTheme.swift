import SwiftUI

enum ApiaryTheme {
    // Palette
    static let sand = Color(red: 232/255, green: 213/255, blue: 163/255)      // #E8D5A3
    static let amber = Color(red: 212/255, green: 155/255, blue: 58/255)       // #D49B3A
    static let sage = Color(red: 107/255, green: 142/255, blue: 78/255)        // #6B8E4E
    static let walnut = Color(red: 90/255, green: 62/255, blue: 42/255)        // #5A3E2A
    static let cream = Color(red: 248/255, green: 241/255, blue: 220/255)      // #F8F1DC
    static let ember = Color(red: 196/255, green: 95/255, blue: 42/255)        // #C45F2A

    // Functional aliases
    static var background: Color { cream }
    static var card: Color { Color(red: 252/255, green: 246/255, blue: 228/255) }
    static var border: Color { walnut.opacity(0.18) }
    static var text: Color { walnut }
    static var subtext: Color { walnut.opacity(0.62) }
    static var primary: Color { amber }
    static var accent: Color { ember }
    static var success: Color { sage }
    static var warning: Color { Color(red: 200/255, green: 145/255, blue: 50/255) }
    static var danger: Color { Color(red: 174/255, green: 67/255, blue: 35/255) }

    // Typography
    static func title(_ size: CGFloat = 22) -> Font {
        Font.system(size: size, weight: .semibold, design: .serif)
    }
    static func heading(_ size: CGFloat = 16) -> Font {
        Font.system(size: size, weight: .semibold, design: .default)
    }
    static func body(_ size: CGFloat = 14) -> Font {
        Font.system(size: size, weight: .regular, design: .default)
    }
    static func mono(_ size: CGFloat = 13) -> Font {
        Font.system(size: size, weight: .medium, design: .monospaced)
    }
}

struct ApiaryCard<Content: View>: View {
    var padding: CGFloat = 14
    let content: () -> Content
    init(padding: CGFloat = 14, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }
    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ApiaryTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ApiaryTheme.border, lineWidth: 1)
            )
    }
}

struct ApiaryPill: View {
    let text: String
    var color: Color = ApiaryTheme.amber
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(
                Capsule().fill(color.opacity(0.18))
            )
            .overlay(
                Capsule().stroke(color.opacity(0.55), lineWidth: 1)
            )
            .foregroundColor(color)
    }
}

struct ApiaryButtonStyle: ButtonStyle {
    var fill: Color = ApiaryTheme.amber
    var foreground: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.8 : 1.0))
            )
            .foregroundColor(foreground)
    }
}

struct ApiaryGhostButtonStyle: ButtonStyle {
    var color: Color = ApiaryTheme.walnut
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(color.opacity(configuration.isPressed ? 0.6 : 1.0))
    }
}

struct ApiaryProgressBar: View {
    let value: Double // 0..1
    var tint: Color = ApiaryTheme.amber
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(ApiaryTheme.walnut.opacity(0.1))
                Capsule().fill(tint)
                    .frame(width: max(0, min(1.0, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct ApiaryStatRow: View {
    let label: String
    let value: String
    var tint: Color = ApiaryTheme.walnut
    var body: some View {
        HStack {
            Text(label).font(ApiaryTheme.body(13)).foregroundColor(ApiaryTheme.subtext)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(tint)
        }
    }
}
