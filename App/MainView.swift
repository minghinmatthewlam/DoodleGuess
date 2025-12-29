import SwiftUI

struct MainView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HomeView()
    }
}
