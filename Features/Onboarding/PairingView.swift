import SwiftUI

struct PairingView: View {
    @EnvironmentObject var app: AppState

    @State private var showingJoinSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Text("Your Pair Code")
                        .font(.headline)

                    Text(app.auth.currentUser?.inviteCode ?? "------")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .tracking(8)

                    Button {
                        UIPasteboard.general.string = app.auth.currentUser?.inviteCode
                    } label: {
                        Label("Copy Code", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(32)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                Text("Share this code with your partner,\nor enter their code below.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    showingJoinSheet = true
                } label: {
                    Text("Enter Partner's Code")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(32)
            .navigationTitle("Connect")
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
}

struct JoinPairSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss

    @State private var code = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Enter your partner's 6-character code")
                    .font(.headline)

                TextField("ABC123", text: $code)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .onChange(of: code) { _, newValue in
                        code = InviteCode.normalize(newValue)
                    }

                if let err = app.pairing.error {
                    Text(err).foregroundColor(.red).font(.caption)
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
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.count != InviteCode.length || app.pairing.isLoading)

                Spacer()
            }
            .padding(32)
            .navigationTitle("Join Partner")
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
