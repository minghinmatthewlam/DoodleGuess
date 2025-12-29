import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: Set<String> = []

    private var userId: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func setUserId(_ userId: String?) {
        guard self.userId != userId else { return }
        self.userId = userId
        loadFavorites()
    }

    func isFavorite(_ drawingId: String?) -> Bool {
        guard let drawingId else { return false }
        return favorites.contains(drawingId)
    }

    func toggleFavorite(_ drawingId: String?) {
        guard let drawingId, userId != nil else { return }
        if favorites.contains(drawingId) {
            favorites.remove(drawingId)
        } else {
            favorites.insert(drawingId)
        }
        persist()
    }

    private func loadFavorites() {
        guard let userId else {
            favorites = []
            return
        }
        let key = storageKey(for: userId)
        let stored = defaults.array(forKey: key) as? [String] ?? []
        favorites = Set(stored)
    }

    private func persist() {
        guard let userId else { return }
        let key = storageKey(for: userId)
        defaults.set(Array(favorites), forKey: key)
    }

    private func storageKey(for userId: String) -> String {
        "favorite_drawings_\(userId)"
    }
}
