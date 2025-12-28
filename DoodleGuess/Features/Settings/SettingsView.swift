import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService

    var body: some View {
        Form {
            Section("Partner") {
                Text(pairing.partner?.name ?? "Not connected")
            }

            Section {
                Button(role: .destructive) {
                    Task {
                        if let me = auth.currentUser?.id {
                            try? await pairing.disconnect(currentUserId: me)
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
