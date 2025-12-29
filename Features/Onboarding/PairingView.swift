import SwiftUI

struct PairingView: View {
    @EnvironmentObject var app: AppState

    @State private var showingJoinSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()

                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 10) {
                        Text("Connect your person")
                            .font(Brand.display(28, weight: .bold))
                            .foregroundColor(Brand.ink)

                        Text("Share your code. They enter it once. Then you just draw.")
                            .font(Brand.text(16))
                            .foregroundColor(Brand.inkSoft)
                            .multilineTextAlignment(.center)
                    }

                    BrandCard {
                        let code = app.auth.currentUser?.inviteCode ?? "------"
                        VStack(spacing: 16) {
                            Text("Your Pair Code")
                                .font(Brand.text(14, weight: .semibold))
                                .foregroundColor(Brand.inkSoft)

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
                        }
                    }

                    BrandCard {
                        VStack(alignment: .leading, spacing: 10) {
                            BrandPill(text: "HOW IT WORKS")
                            Text("They add the widget, and your drawings show up there.")
                                .font(Brand.text(16, weight: .semibold))
                                .foregroundColor(Brand.ink)
                            Text("Once paired, you can start drawing right away.")
                                .font(Brand.text(14))
                                .foregroundColor(Brand.inkSoft)
                        }
                    }

                    Spacer()

                    Button {
                        showingJoinSheet = true
                    } label: {
                        Text("Enter Partner Code")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingJoinSheet) {
                JoinPairSheet()
            }
            .onChange(of: app.pairing.isPaired) { _, isPaired in
                if isPaired {
                    (UIApplication.shared.delegate as? AppDelegate)?.requestPushPermissions()
                }
            }
        }
    }

    private func shareText(code: String) -> String {
        "Join me on Doodle Guess. My code is \(code)."
    }
}

struct JoinPairSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss

    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                BrandBackground()

                VStack(spacing: 24) {
                    Text("Enter their code")
                        .font(Brand.display(22, weight: .bold))
                        .foregroundColor(Brand.ink)

                    TextField("ABC123", text: $code)
                        .font(Brand.display(28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                                )
                        )
                        .onChange(of: code) { _, newValue in
                            code = InviteCode.normalize(newValue)
                        }

                    Button {
                        if let pasted = UIPasteboard.general.string {
                            code = InviteCode.normalize(pasted)
                        }
                    } label: {
                        Label("Paste Code", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    if let err = app.pairing.error {
                        Text(err)
                            .font(Brand.text(13, weight: .medium))
                            .foregroundColor(.red)
                    }

                    Button {
                        Task {
                            guard let me = app.auth.currentUser?.id else { return }
                            try? await app.pairing.joinWithCode(code, currentUserId: me)
                            if app.pairing.isPaired { dismiss() }
                        }
                    } label: {
                        if app.pairing.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Connect")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(code.count != InviteCode.length || app.pairing.isLoading)

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }
}

struct InviteCodeDisplay: View {
    let code: String

    var body: some View {
        let tokens = Array(code.padding(toLength: InviteCode.length, withPad: "-", startingAt: 0)).map { String($0) }

        HStack(spacing: 8) {
            ForEach(tokens.indices, id: \.self) { idx in
                Text(tokens[idx])
                    .font(Brand.display(24, weight: .bold))
                    .frame(width: 38, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
        }
    }
}
