import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    @State private var drawingRoute: DrawingRoute?

    var body: some View {
        NavigationStack {
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
            .navigationDestination(item: $drawingRoute) { route in
                DrawingDetailView(drawingId: route.id)
            }
        }
        .task {
            await app.start()
            syncPath()
        }
        .onChange(of: app.deepLink.drawingId) { _, _ in
            syncPath()
        }
        .onChange(of: app.auth.isAuthenticated) { _, _ in
            syncPath()
        }
        .onChange(of: app.auth.isLoading) { _, _ in
            syncPath()
        }
        .onChange(of: app.pairing.isPaired) { _, _ in
            syncPath()
        }
        .onOpenURL { url in
            app.deepLink.handle(url: url)
        }
    }

    private func syncPath() {
        guard !app.auth.isLoading, app.auth.isAuthenticated, app.pairing.isPaired else {
            drawingRoute = nil
            return
        }
        guard let drawingId = app.deepLink.drawingId else {
            drawingRoute = nil
            return
        }
        drawingRoute = DrawingRoute(id: drawingId)
    }
}

private struct DrawingRoute: Identifiable, Hashable {
    let id: String
}
