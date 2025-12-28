import SwiftUI

#if canImport(FirebaseCore)
    import FirebaseCore
#endif

@main
struct DoodleGuessApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState()

    init() {
        #if canImport(FirebaseCore)
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
