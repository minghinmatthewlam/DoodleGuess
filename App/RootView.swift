import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case let .drawing(id):
                    DrawingDetailView(drawingId: id)
                }
            }
        }
        .task {
            await app.start()
            syncPath()
        }
        .onChange(of: app.deepLink.drawingId) { _, _ in
            syncPath()
        }
        .onOpenURL { url in
            app.deepLink.handle(url: url)
        }
    }

    private func syncPath() {
        guard let drawingId = app.deepLink.drawingId else {
            path = NavigationPath()
            return
        }
        path = NavigationPath([Route.drawing(drawingId)])
    }
}

private enum Route: Hashable {
    case drawing(String)
}
