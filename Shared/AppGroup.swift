import Foundation

enum AppGroup {
    static let id = "group.com.example.doodleguess"

    // Override for tests to avoid requiring App Group entitlements.
    static var overrideURL: URL?

    static var containerURL: URL {
        if let overrideURL {
            return overrideURL
        }
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) else {
            fatalError("Missing App Group container URL. Configure App Groups for both targets.")
        }
        return url
    }
}
