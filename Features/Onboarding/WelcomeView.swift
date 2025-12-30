import SwiftUI

private struct OnboardingSlide: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let description: String
    let colors: [Color]
}

private let onboardingSlides: [OnboardingSlide] = [
    OnboardingSlide(
        emoji: "👋",
        title: "Welcome to Doodle Guess!",
        description: "Stay connected with your favorite people through creative doodles.",
        colors: [Brand.accent, Brand.accent2]
    ),
    OnboardingSlide(
        emoji: "✏️",
        title: "Draw & Send",
        description: "Create fun drawings, add photos, and send love notes to your partner.",
        colors: [Brand.accent2, Color(red: 0.96, green: 0.46, blue: 0.48)]
    ),
    OnboardingSlide(
        emoji: "📱",
        title: "Widget Magic",
        description: "See their latest doodles right on your home screen widget.",
        colors: [Brand.accent3, Brand.accent]
    ),
    OnboardingSlide(
        emoji: "💕",
        title: "Keep Memories",
        description: "Save and favorite your best moments together.",
        colors: [Color(red: 0.96, green: 0.52, blue: 0.55), Brand.accent2]
    ),
]

struct WelcomeView: View {
    @EnvironmentObject var app: AppState
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    @State private var currentSlide = 0
    @State private var showNameInput = false
    @State private var name = ""
    @State private var isSaving = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        if showNameInput {
            nameEntry
        } else {
            slideView
        }
    }

    private var slideView: some View {
        let slide = onboardingSlides[currentSlide]
        return ZStack {
            LinearGradient(
                colors: slide.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        showNameInput = true
                    }
                    .font(Brand.text(14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                }

                Spacer()

                VStack(spacing: 18) {
                    Text(slide.emoji)
                        .font(.system(size: 72))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

                    Text(slide.title)
                        .font(Brand.display(32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(slide.description)
                        .font(Brand.text(18))
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 22)

                Spacer()

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(onboardingSlides.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == currentSlide ? Color.white : Color.white.opacity(0.4))
                                .frame(width: index == currentSlide ? 28 : 8, height: 8)
                        }
                    }

                    Button {
                        handleNext()
                    } label: {
                        Text(currentSlide == onboardingSlides.count - 1 ? "Let's Go!" : "Next")
                            .font(Brand.text(18, weight: .semibold))
                            .foregroundColor(Brand.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                    .fill(Color.white)
                            )
                    }
                }
            }
            .padding(24)
        }
    }

    private var nameEntry: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.accent, Brand.accent2, Color(red: 0.96, green: 0.46, blue: 0.48)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
                    Text("🎨")
                        .font(.system(size: 60))

                    Text("What's your name?")
                        .font(Brand.display(26, weight: .bold))
                        .foregroundColor(Brand.ink)

                    Text("Your partner will see this when you connect.")
                        .font(Brand.text(15))
                        .foregroundColor(Brand.inkSoft)
                        .multilineTextAlignment(.center)

                    TextField("Enter your name", text: $name)
                        .font(Brand.text(17, weight: .semibold))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Brand.ink.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .multilineTextAlignment(.center)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit { submitName() }

                    Button {
                        submitName()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        } else {
                            Text("Get Started")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Brand.ink.opacity(0.18), radius: 24, x: 0, y: 12)
                )
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear { nameFocused = true }
    }

    private func handleNext() {
        if currentSlide < onboardingSlides.count - 1 {
            currentSlide += 1
        } else {
            showNameInput = true
        }
    }

    private func submitName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        Task { @MainActor in
            await app.auth.updateName(trimmed)
            onboardingComplete = true
            isSaving = false
        }
    }
}
