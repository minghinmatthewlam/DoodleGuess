import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService
    @EnvironmentObject var drawings: DrawingService

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView("Loading...")
            } else if !auth.isAuthenticated {
                WelcomeView()
            } else if !pairing.isPaired {
                PairingView()
            } else {
                MainView()
            }
        }
        .task { await initialSetup() }
    }

    private func initialSetup() async {
        if !auth.isAuthenticated {
            try? await auth.signInAnonymously()
        }

        if let me = auth.currentUser {
            // Ensure my invite code has a pair doc behind it.
            await pairing.ensurePairExistsForMyInviteCode(currentUser: me)

            // Check pairing state (loads partner if paired)
            if let myId = me.id {
                await pairing.checkPairingStatus(currentUserId: myId)
            }

            // If paired, start listening for drawings
            if pairing.isPaired, let myId = auth.currentUser?.id, let partnerName = pairing.partner?.name {
                drawings.startListeningForDrawings(userId: myId, partnerName: partnerName)
            }
        }
    }
}
