import SwiftUI

private enum PairingMode {
    case choose
    case create
    case join
}

struct PairingView: View {
    @EnvironmentObject var app: AppState

    @State private var mode: PairingMode = .choose
    @State private var joinCode = ""
    @State private var localError: String?
    @FocusState private var joinFocused: Bool

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 22) {
                Spacer()

                header

                content

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: app.pairing.isPaired) { _, isPaired in
            if isPaired {
                (UIApplication.shared.delegate as? AppDelegate)?.requestPushPermissions()
            }
        }
        .task(id: mode) {
            guard mode == .create else { return }
            while !Task.isCancelled, !app.pairing.isPaired {
                if let me = app.auth.currentUser?.id {
                    await app.pairing.checkPairingStatus(currentUserId: me)
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Connect with Partner")
                .font(Brand.display(30, weight: .bold))
                .foregroundColor(Brand.ink)

            Text("Share your code or join theirs to start doodling.")
                .font(Brand.text(16))
                .foregroundColor(Brand.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .choose:
            chooseView
        case .create:
            createView
        case .join:
            joinView
        }
    }

    private var chooseView: some View {
        VStack(spacing: 16) {
            choiceCard(
                title: "Create Code",
                subtitle: "Generate a code for your partner to join",
                emoji: "✨",
                colors: [Brand.accent, Brand.accent2],
                isGradient: true
            ) {
                mode = .create
            }

            choiceCard(
                title: "Join Partner",
                subtitle: "Enter your partner's code",
                emoji: "🔗",
                colors: [Color.white, Color.white],
                isGradient: false
            ) {
                mode = .join
                joinFocused = true
            }
        }
    }

    private var createView: some View {
        BrandCard {
            let code = app.auth.currentUser?.inviteCode ?? "------"
            VStack(spacing: 18) {
                Text("Share this code")
                    .font(Brand.text(18, weight: .semibold))
                    .foregroundColor(Brand.ink)

                Text("Send this to your partner to connect.")
                    .font(Brand.text(14))
                    .foregroundColor(Brand.inkSoft)
                    .multilineTextAlignment(.center)

                InviteCodeDisplay(code: code)

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    ShareLink(item: shareText(code: code)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Text("Waiting for partner to join...")
                    .font(Brand.text(13, weight: .medium))
                    .foregroundColor(Brand.inkSoft)

                Button("Back") {
                    mode = .choose
                }
                .font(Brand.text(14, weight: .semibold))
                .foregroundColor(Brand.inkSoft)
                .padding(.top, 6)
            }
        }
    }

    private var joinView: some View {
        BrandCard {
            VStack(spacing: 16) {
                Text("Join Partner")
                    .font(Brand.text(20, weight: .semibold))
                    .foregroundColor(Brand.ink)

                Text("Enter the 6-letter code")
                    .font(Brand.text(14))
                    .foregroundColor(Brand.inkSoft)

                TextField("ABC123", text: $joinCode)
                    .font(Brand.display(26, weight: .bold))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($joinFocused)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Brand.ink.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .onChange(of: joinCode) { _, newValue in
                        joinCode = InviteCode.normalize(newValue)
                        localError = nil
                    }

                if let err = localError ?? app.pairing.error {
                    Text(err)
                        .font(Brand.text(13, weight: .medium))
                        .foregroundColor(.red)
                }

                Button {
                    Task {
                        guard let me = app.auth.currentUser?.id else { return }
                        do {
                            try await app.pairing.joinWithCode(joinCode, currentUserId: me)
                        } catch {
                            localError = error.localizedDescription
                        }
                    }
                } label: {
                    if app.pairing.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Connect 🚀")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(joinCode.count != InviteCode.length || app.pairing.isLoading)

                Button("Back") {
                    mode = .choose
                    joinCode = ""
                    localError = nil
                }
                .font(Brand.text(14, weight: .semibold))
                .foregroundColor(Brand.inkSoft)
            }
        }
        .onAppear { joinFocused = true }
    }

    private func choiceCard(
        title: String,
        subtitle: String,
        emoji: String,
        colors: [Color],
        isGradient: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 32))
                Text(title)
                    .font(Brand.text(18, weight: .semibold))
                Text(subtitle)
                    .font(Brand.text(13))
                    .foregroundColor(Brand.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isGradient ? .white : Brand.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Brand.ink.opacity(isGradient ? 0 : 0.12), lineWidth: 1)
                    )
                    .shadow(color: Brand.ink.opacity(0.12), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    private func shareText(code: String) -> String {
        "Join me on Doodle Guess. My code is \(code)."
    }
}

struct InviteCodeDisplay: View {
    let code: String

    var body: some View {
        let tokens = Array(code.padding(toLength: InviteCode.length, withPad: "-", startingAt: 0)).map { String($0) }

        HStack(spacing: 8) {
            ForEach(tokens.indices, id: \.self) { idx in
                Text(tokens[idx])
                    .font(Brand.display(22, weight: .bold))
                    .frame(width: 36, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Brand.ink.opacity(0.12), lineWidth: 1)
                            )
                    )
            }
        }
    }
}
