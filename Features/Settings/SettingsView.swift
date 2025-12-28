import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        Form {
            Section("Partner") {
                Text(app.pairing.partner?.name ?? "Not connected")
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        if let me = app.auth.currentUser?.id {
                            try? await app.pairing.disconnect(currentUserId: me)
                        }
                    }
                } label: {
                    Text("Disconnect")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
