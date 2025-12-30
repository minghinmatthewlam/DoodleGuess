import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: Set<String> = []

    private let defaults: UserDefaults
    private let storageKey = "favorite_drawings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFavorites()
    }

    func setUserId(_ userId: String?) {
        migrateLegacyFavorites(userId)
    }

    func isFavorite(_ drawingId: String?) -> Bool {
        guard let drawingId else { return false }
        return favorites.contains(drawingId)
    }

    func toggleFavorite(_ drawingId: String?) {
        guard let drawingId else { return }
        if favorites.contains(drawingId) {
            favorites.remove(drawingId)
        } else {
            favorites.insert(drawingId)
        }
        persist()
    }

    private func loadFavorites() {
        let stored = defaults.array(forKey: storageKey) as? [String] ?? []
        favorites = Set(stored)
    }

    private func persist() {
        defaults.set(Array(favorites), forKey: storageKey)
    }

    private func migrateLegacyFavorites(_ userId: String?) {
        guard let userId else { return }
        let legacyKey = "favorite_drawings_\(userId)"
        guard let legacy = defaults.array(forKey: legacyKey) as? [String], !legacy.isEmpty else { return }
        favorites.formUnion(legacy)
        persist()
        defaults.removeObject(forKey: legacyKey)
    }
}
