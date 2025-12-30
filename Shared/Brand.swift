import SwiftUI

enum Brand {
    static let backgroundTop = Color(red: 0.97, green: 0.95, blue: 1.0)
    static let backgroundMid = Color(red: 1.0, green: 0.95, blue: 0.98)
    static let backgroundBottom = Color(red: 0.94, green: 0.97, blue: 1.0)
    static let canvasBackground = Color(red: 0.97, green: 0.97, blue: 0.99)
    static let ink = Color(red: 0.16, green: 0.16, blue: 0.20)
    static let inkSoft = Color(red: 0.45, green: 0.45, blue: 0.55)
    static let accent = Color(red: 0.54, green: 0.36, blue: 0.95)
    static let accent2 = Color(red: 0.93, green: 0.36, blue: 0.62)
    static let accent3 = Color(red: 0.24, green: 0.67, blue: 0.84)
    static let accent4 = Color(red: 0.24, green: 0.75, blue: 0.68)

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom("Avenir Next", size: size).weight(weight)
    }

    static func text(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Avenir Next", size: size).weight(weight)
    }
}

struct BrandBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.backgroundTop, Brand.backgroundMid, Brand.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Brand.accent.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 34)
                .offset(x: -140, y: -180)

            Circle()
                .fill(Brand.accent4.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 42)
                .offset(x: 170, y: 220)
        }
        .ignoresSafeArea()
    }
}

struct BrandCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Brand.ink.opacity(0.12), radius: 18, x: 0, y: 10)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.text(18, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Brand.accent, Brand.accent2],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.text(16, weight: .medium))
            .foregroundColor(Brand.ink)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Brand.ink.opacity(0.12), lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.text(16, weight: .semibold))
            .foregroundColor(Color.red.opacity(0.9))
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct BrandPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Brand.text(12, weight: .semibold))
            .foregroundColor(Brand.inkSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .overlay(Capsule().stroke(Brand.ink.opacity(0.12), lineWidth: 1))
            )
    }
}
