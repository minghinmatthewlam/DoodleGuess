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
                            if let newCode = try? await pairing.disconnect(currentUserId: me) {
                                auth.updateLocalInviteCode(newCode)
                            }
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
