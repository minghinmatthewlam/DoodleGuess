import Foundation

#if canImport(FirebaseFirestore) && canImport(FirebaseFirestoreSwift)
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class PairingService: ObservableObject {
    @Published var isPaired = false
    @Published var partner: AppUser?
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private var partnerListener: ListenerRegistration?

    func ensurePairExistsForMyInviteCode(currentUser: AppUser) async {
        guard let myId = currentUser.id else { return }
        let code = currentUser.inviteCode.uppercased()

        let pairRef = db.collection("pairs").document(code)
        do {
            let snap = try await pairRef.getDocument()
            if snap.exists { return }

            let pair = Pair(id: code, code: code, user1Id: myId, user2Id: nil, createdAt: Date())
            try pairRef.setData(from: pair)
        } catch {
            print("ensurePairExistsForMyInviteCode error: \(error)")
        }
    }

    func joinWithCode(_ code: String, currentUserId: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let normalized = InviteCode.normalize(code)
        guard normalized.count == InviteCode.length else {
            error = "Code must be 6 characters."
            throw PairingError.invalidCode
        }

        let pairRef = db.collection("pairs").document(normalized)
        let meRef = db.collection("users").document(currentUserId)

        _ = try await db.runTransaction { txn, errorPointer in
            let pairSnap: DocumentSnapshot
            do {
                pairSnap = try txn.getDocument(pairRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            guard let data = pairSnap.data() else {
                errorPointer?.pointee = PairingError.invalidCode as NSError
                return nil
            }

            let user1Id = data["user1Id"] as? String ?? ""
            let user2Id = data["user2Id"] as? String

            if user1Id.isEmpty {
                errorPointer?.pointee = PairingError.invalidCode as NSError
                return nil
            }
            if user1Id == currentUserId {
                errorPointer?.pointee = PairingError.selfPairing as NSError
                return nil
            }
            if user2Id != nil {
                errorPointer?.pointee = PairingError.alreadyPaired as NSError
                return nil
            }

            txn.updateData(["user2Id": currentUserId], forDocument: pairRef)

            let user1Ref = self.db.collection("users").document(user1Id)
            txn.setData(["pairId": normalized, "partnerId": currentUserId], forDocument: user1Ref, merge: true)
            txn.setData(["pairId": normalized, "partnerId": user1Id], forDocument: meRef, merge: true)

            return user1Id
        }

        try await loadPartnerAndListen(currentUserId: currentUserId)
    }

    func checkPairingStatus(currentUserId: String) async {
        do {
            let snap = try await db.collection("users").document(currentUserId).getDocument()
            guard let me = try? snap.data(as: AppUser.self),
                  let partnerId = me.partnerId else {
                isPaired = false
                partner = nil
                return
            }

            try await loadPartnerAndListen(currentUserId: currentUserId)
        } catch {
            print("checkPairingStatus error: \(error)")
        }
    }

    private func loadPartnerAndListen(currentUserId: String) async throws {
        let mySnap = try await db.collection("users").document(currentUserId).getDocument()
        guard let me = try? mySnap.data(as: AppUser.self),
              let partnerId = me.partnerId else {
            isPaired = false
            partner = nil
            return
        }

        let partnerSnap = try await db.collection("users").document(partnerId).getDocument()
        if let partnerUser = try? partnerSnap.data(as: AppUser.self) {
            self.partner = partnerUser
            self.isPaired = true
            startPartnerListener(partnerId: partnerId)
        }
    }

    private func startPartnerListener(partnerId: String) {
        partnerListener?.remove()
        partnerListener = db.collection("users").document(partnerId)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let snap else { return }
                guard let partner = try? snap.data(as: AppUser.self) else { return }

                Task { @MainActor in
                    if partner.partnerId == nil {
                        self.isPaired = false
                        self.partner = nil
                    } else {
                        self.partner = partner
                    }
                }
            }
    }

    func disconnect(currentUserId: String) async throws {
        guard let partnerId = partner?.id else { return }

        isLoading = true
        defer { isLoading = false }

        let batch = db.batch()
        let meRef = db.collection("users").document(currentUserId)
        let partnerRef = db.collection("users").document(partnerId)

        let myNewCode = AppUser.generateInviteCode()
        let partnerNewCode = AppUser.generateInviteCode()

        batch.updateData([
            "partnerId": FieldValue.delete(),
            "pairId": FieldValue.delete(),
            "inviteCode": myNewCode
        ], forDocument: meRef)

        batch.updateData([
            "partnerId": FieldValue.delete(),
            "pairId": FieldValue.delete(),
            "inviteCode": partnerNewCode
        ], forDocument: partnerRef)

        try await batch.commit()

        partnerListener?.remove()
        isPaired = false
        partner = nil

        let newPairRef = db.collection("pairs").document(myNewCode)
        let newPair = Pair(id: myNewCode, code: myNewCode, user1Id: currentUserId, user2Id: nil, createdAt: Date())
        try? newPairRef.setData(from: newPair)
    }

    deinit { partnerListener?.remove() }
}

enum PairingError: LocalizedError {
    case invalidCode
    case selfPairing
    case alreadyPaired

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid pair code"
        case .selfPairing: return "Cannot pair with yourself"
        case .alreadyPaired: return "User is already paired"
        }
    }
}

#else

@MainActor
final class PairingService: ObservableObject {
    @Published var isPaired = false
    @Published var partner: AppUser?
    @Published var isLoading = false
    @Published var error: String?

    func ensurePairExistsForMyInviteCode(currentUser: AppUser) async {
        // No-op without Firebase.
    }

    func joinWithCode(_ code: String, currentUserId: String) async throws {
        let normalized = InviteCode.normalize(code)
        guard normalized.count == InviteCode.length else {
            error = "Code must be 6 characters."
            throw PairingError.invalidCode
        }

        isPaired = true
        partner = AppUser(
            id: UUID().uuidString,
            name: "Partner",
            partnerId: currentUserId,
            pairId: normalized,
            inviteCode: AppUser.generateInviteCode(),
            deviceToken: nil,
            createdAt: Date()
        )
    }

    func checkPairingStatus(currentUserId: String) async {
        // No-op without Firebase.
    }

    func disconnect(currentUserId: String) async throws {
        isPaired = false
        partner = nil
    }
}

enum PairingError: LocalizedError {
    case invalidCode
    case selfPairing
    case alreadyPaired

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid pair code"
        case .selfPairing: return "Cannot pair with yourself"
        case .alreadyPaired: return "User is already paired"
        }
    }
}

#endif
