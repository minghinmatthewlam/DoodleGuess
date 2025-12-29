import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    let auth: AuthService
    let pairing: PairingService
    let drawings: DrawingService
    let favorites: FavoritesStore
    let deepLink: DeepLinkRouter

    private var cancellables = Set<AnyCancellable>()
    private var didStart = false

    init(
        auth: AuthService? = nil,
        pairing: PairingService? = nil,
        drawings: DrawingService? = nil,
        favorites: FavoritesStore? = nil,
        deepLink: DeepLinkRouter? = nil
    ) {
        self.auth = auth ?? AuthService()
        self.pairing = pairing ?? PairingService()
        self.drawings = drawings ?? DrawingService()
        self.favorites = favorites ?? FavoritesStore()
        self.deepLink = deepLink ?? DeepLinkRouter()

        bindServiceChangeForwarding()
        bindPairingState()
        bindFavorites()
    }

    func start() async {
        guard !didStart else { return }
        didStart = true

        if !auth.isAuthenticated {
            try? await auth.signInAnonymously()
        }

        if let me = auth.currentUser {
            await pairing.ensurePairExistsForMyInviteCode(currentUser: me)

            if let myId = me.id {
                await pairing.checkPairingStatus(currentUserId: myId)
            }
        }

        updateListeners(user: auth.currentUser, isPaired: pairing.isPaired, partner: pairing.partner)
    }

    private func bindServiceChangeForwarding() {
        // CRITICAL: Forward nested service changes so RootView re-renders on auth/pairing/drawings/deepLink updates.
        // Without this, deep links and auth state changes can appear to "do nothing" because RootView won't refresh.
        auth.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        pairing.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        drawings.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        favorites.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        deepLink.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func bindPairingState() {
        Publishers.CombineLatest3(auth.$currentUser, pairing.$isPaired, pairing.$partner)
            .receive(on: RunLoop.main)
            .sink { [weak self] user, isPaired, partner in
                self?.updateListeners(user: user, isPaired: isPaired, partner: partner)
            }
            .store(in: &cancellables)
    }

    private func bindFavorites() {
        auth.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.favorites.setUserId(user?.id)
            }
            .store(in: &cancellables)
    }

    private func updateListeners(user: AppUser?, isPaired: Bool, partner: AppUser?) {
        if isPaired, let userId = user?.id, let partnerName = partner?.name {
            drawings.startListeningForDrawings(userId: userId, partnerName: partnerName)
        } else {
            drawings.stopListeningForDrawings()
        }
    }
}
