import SwiftUI

enum Brand {
    static let paper = Color(red: 0.97, green: 0.94, blue: 0.89)
    static let paperDeep = Color(red: 0.94, green: 0.90, blue: 0.84)
    static let ink = Color(red: 0.13, green: 0.11, blue: 0.10)
    static let inkSoft = Color(red: 0.36, green: 0.31, blue: 0.28)
    static let accent = Color(red: 0.95, green: 0.45, blue: 0.36)
    static let accent2 = Color(red: 0.20, green: 0.67, blue: 0.63)

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
                colors: [Brand.paper, Brand.paperDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Brand.accent.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .offset(x: -140, y: -180)

            Circle()
                .fill(Brand.accent2.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
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
                    .fill(Brand.paper.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Brand.ink.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Brand.ink.opacity(0.08), radius: 16, x: 0, y: 8)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.text(18, weight: .semibold))
            .foregroundColor(Brand.ink)
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
                    .fill(Color.white.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.text(16, weight: .semibold))
            .foregroundColor(.red)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
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
                    .fill(Color.white.opacity(0.7))
                    .overlay(Capsule().stroke(Brand.ink.opacity(0.08), lineWidth: 1))
            )
    }
}
