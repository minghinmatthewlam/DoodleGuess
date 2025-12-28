import Foundation

enum AppGroup {
    static let id = "group.com.matthewlam.doodleguess"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }
}
