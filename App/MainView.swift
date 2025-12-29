import SwiftUI

struct MainView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        List {
            NavigationLink("Draw") { CanvasScreen() }
            NavigationLink("History") { HistoryView() }
            NavigationLink("Settings") { SettingsView() }
        }
        .navigationTitle("Doodle Guess")
    }
}
