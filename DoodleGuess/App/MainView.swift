import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Draw") { CanvasScreen() }
                NavigationLink("History") { HistoryView() }
                NavigationLink("Settings") { SettingsView() }
            }
            .navigationTitle("Doodle Guess")
        }
    }
}
