import SwiftUI

#if canImport(FirebaseCore)
    import FirebaseCore
#endif

@main
struct DoodleGuessApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var auth = AuthService()
    @StateObject private var pairing = PairingService()
    @StateObject private var drawings = DrawingService()
    @StateObject private var deepLink = DeepLinkRouter()

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
                .environmentObject(auth)
                .environmentObject(pairing)
                .environmentObject(drawings)
                .environmentObject(deepLink)
        }
    }
}
