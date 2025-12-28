import Foundation

#if canImport(FirebaseFirestoreSwift)
import FirebaseFirestoreSwift
#endif

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var partnerId: String?
    var pairId: String?
    var inviteCode: String
    var deviceToken: String?
    var createdAt: Date

    init(
        id: String?,
        name: String,
        partnerId: String?,
        pairId: String?,
        inviteCode: String,
        deviceToken: String?,
        createdAt: Date
    ) {
        self._id = DocumentID(wrappedValue: id)
        self.name = name
        self.partnerId = partnerId
        self.pairId = pairId
        self.inviteCode = inviteCode
        self.deviceToken = deviceToken
        self.createdAt = createdAt
    }

    static func generateInviteCode() -> String {
        InviteCode.generate()
    }
}
