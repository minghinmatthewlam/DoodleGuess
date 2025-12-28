import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        Group {
            if app.auth.isLoading {
                ProgressView("Loading...")
            } else if !app.auth.isAuthenticated {
                WelcomeView()
            } else if !app.pairing.isPaired {
                PairingView()
            } else {
                MainView()
            }
        }
        .task { await app.start() }
        .onOpenURL { url in
            app.deepLink.handle(url: url)
        }
    }
}
