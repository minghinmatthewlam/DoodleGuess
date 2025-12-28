import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var app: AppState
    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "pencil.tip.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(.blue, .blue.opacity(0.3))

            VStack(spacing: 12) {
                Text("Doodle Guess")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Draw for your partner.\nTheir drawing appears on your widget.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSigningIn)
        }
        .padding(32)
    }
}
