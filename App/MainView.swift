import SwiftUI

struct MainView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        TabView {
            NavigationStack {
                CanvasScreen()
            }
            .tabItem {
                Label("Draw", systemImage: "pencil.tip")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("Gallery", systemImage: "square.grid.2x2")
            }
        }
    }
}
