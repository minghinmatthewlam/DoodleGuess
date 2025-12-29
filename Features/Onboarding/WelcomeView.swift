import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var app: AppState
    @State private var isSigningIn = false

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.75))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                            )

                        Image(systemName: "scribble.variable")
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundColor(Brand.ink)
                    }

                    VStack(spacing: 10) {
                        Text("Doodle Guess")
                            .font(Brand.display(36, weight: .bold))
                            .foregroundColor(Brand.ink)

                        Text("A tiny ritual for two. Draw once, feel close all day.")
                            .font(Brand.text(17))
                            .foregroundColor(Brand.inkSoft)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }

                BrandCard {
                    VStack(alignment: .leading, spacing: 12) {
                        BrandPill(text: "WIDGET FIRST")
                        Text("Their latest drawing lives on your home screen.")
                            .font(Brand.text(18, weight: .semibold))
                            .foregroundColor(Brand.ink)
                        Text("No feeds. No streaks. Just a glanceable moment.")
                            .font(Brand.text(15))
                            .foregroundColor(Brand.inkSoft)
                    }
                }

                Spacer()

                Button {
                    Task {
                        isSigningIn = true
                        try? await app.auth.signInAnonymously()
                        isSigningIn = false
                    }
                } label: {
                    if isSigningIn {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSigningIn)

                Text("Pair up in 30 seconds.")
                    .font(Brand.text(14, weight: .medium))
                    .foregroundColor(Brand.inkSoft)
            }
            .padding(24)
        }
    }
}
