import Foundation

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseFirestoreSwift)
    import FirebaseAuth
    import FirebaseFirestore
    import FirebaseFirestoreSwift

    @MainActor
    final class AuthService: ObservableObject {
        @Published var currentUser: AppUser?
        @Published var isAuthenticated = false
        @Published var isLoading = true

        private let db = Firestore.firestore()
        private var authListener: AuthStateDidChangeListenerHandle?

        init() {
            setupAuthListener()

            NotificationCenter.default.addObserver(
                forName: Notification.Name("FCMTokenReceived"),
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let token = note.userInfo?["token"] as? String else { return }
                Task { await self?.updateDeviceToken(token) }
            }
        }

        private func setupAuthListener() {
            authListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
                Task { @MainActor in
                    guard let self else { return }
                    if let firebaseUser {
                        await self.loadOrCreateUser(firebaseUserId: firebaseUser.uid)
                    } else {
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                    self.isLoading = false
                }
            }
        }

        func signInAnonymously() async throws {
            let result = try await Auth.auth().signInAnonymously()
            await loadOrCreateUser(firebaseUserId: result.user.uid)
        }

        private func loadOrCreateUser(firebaseUserId: String) async {
            let ref = db.collection("users").document(firebaseUserId)

            do {
                let snap = try await ref.getDocument()

                if snap.exists, let user = try? snap.data(as: AppUser.self) {
                    currentUser = user
                    isAuthenticated = true
                    return
                }

                let code = AppUser.generateInviteCode()
                let newUser = AppUser(
                    id: firebaseUserId,
                    name: "User",
                    partnerId: nil,
                    pairId: nil,
                    inviteCode: code,
                    deviceToken: nil,
                    createdAt: Date()
                )

                try ref.setData(from: newUser)
                currentUser = newUser
                isAuthenticated = true
            } catch {
                print("Error loadOrCreateUser: \(error)")
            }
        }

        func updateName(_ name: String) async {
            guard let userId = currentUser?.id else { return }
            do {
                try await db.collection("users").document(userId).updateData(["name": name])
                currentUser?.name = name
            } catch {
                print("updateName failed: \(error)")
            }
        }

        func updateDeviceToken(_ token: String) async {
            guard let userId = currentUser?.id else { return }
            do {
                try await db.collection("users").document(userId).updateData(["deviceToken": token])
                currentUser?.deviceToken = token
            } catch {
                print("updateDeviceToken failed: \(error)")
            }
        }

        func signOut() throws {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        }

        deinit {
            if let authListener { Auth.auth().removeStateDidChangeListener(authListener) }
            NotificationCenter.default.removeObserver(self)
        }
    }

#else

    @MainActor
    final class AuthService: ObservableObject {
        @Published var currentUser: AppUser?
        @Published var isAuthenticated = false
        @Published var isLoading = false

        func signInAnonymously() async throws {
            let user = AppUser(
                id: UUID().uuidString,
                name: "User",
                partnerId: nil,
                pairId: nil,
                inviteCode: AppUser.generateInviteCode(),
                deviceToken: nil,
                createdAt: Date()
            )
            currentUser = user
            isAuthenticated = true
        }

        func updateName(_ name: String) async {
            currentUser?.name = name
        }

        func updateDeviceToken(_ token: String) async {
            currentUser?.deviceToken = token
        }

        func signOut() throws {
            currentUser = nil
            isAuthenticated = false
        }
    }

#endif
