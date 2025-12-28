import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService
    @EnvironmentObject var drawings: DrawingService
    @EnvironmentObject var deepLink: DeepLinkRouter

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
        .onOpenURL { url in
            deepLink.handle(url: url)
        }
        .onChange(of: pairing.isPaired) { _, isPaired in
            if isPaired {
                startListeningIfPossible()
            } else {
                drawings.stopListeningForDrawings()
            }
        }
        .onChange(of: pairing.partner?.name) { _, _ in
            startListeningIfPossible()
        }
    }

    private func initialSetup() async {
        if !auth.isAuthenticated {
            try? await auth.signInAnonymously()
        }

        if let me = auth.currentUser {
            await pairing.ensurePairExistsForMyInviteCode(currentUser: me)

            if let myId = me.id {
                await pairing.checkPairingStatus(currentUserId: myId)
            }

            startListeningIfPossible()
        }
    }

    private func startListeningIfPossible() {
        guard pairing.isPaired,
              let myId = auth.currentUser?.id,
              let partnerName = pairing.partner?.name else {
            return
        }

        drawings.startListeningForDrawings(userId: myId, partnerName: partnerName)
    }
}
