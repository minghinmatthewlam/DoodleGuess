import SwiftUI

struct MainView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Draw") { CanvasScreen() }
                NavigationLink("History") { HistoryView() }
                NavigationLink("Settings") { SettingsView() }
            }
            .navigationTitle("Doodle Guess")
            .navigationDestination(isPresented: Binding(
                get: { app.deepLink.drawingId != nil },
                set: { if !$0 { app.deepLink.drawingId = nil } }
            )) {
                DrawingDetailView(drawingId: app.deepLink.drawingId)
            }
        }
    }
}
