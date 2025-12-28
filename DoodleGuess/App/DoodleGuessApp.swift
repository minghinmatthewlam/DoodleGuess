import SwiftUI
import FirebaseCore

@main
struct DoodleGuessApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var auth = AuthService()
    @StateObject private var pairing = PairingService()
    @StateObject private var drawings = DrawingService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(pairing)
                .environmentObject(drawings)
        }
    }
}
