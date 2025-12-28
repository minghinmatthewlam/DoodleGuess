import SwiftUI

struct MainView: View {
    @EnvironmentObject var deepLink: DeepLinkRouter
    @EnvironmentObject var drawings: DrawingService

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Draw") { CanvasScreen() }
                NavigationLink("History") { HistoryView() }
                NavigationLink("Settings") { SettingsView() }
            }
            .navigationTitle("Doodle Guess")
            .navigationDestination(isPresented: Binding(
                get: { deepLink.drawingId != nil },
                set: { if !$0 { deepLink.drawingId = nil } }
            )) {
                DrawingDetailView(drawingId: deepLink.drawingId)
            }
        }
    }
}
