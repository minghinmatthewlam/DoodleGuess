import SwiftUI

@main
struct DoodleGuessApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState: AppState

    init() {
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
