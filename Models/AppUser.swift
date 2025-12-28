import Foundation

struct AppUser: Codable, Identifiable {
    var id: String?
    var name: String
    var partnerId: String?
    var pairId: String?
    var inviteCode: String
    var deviceToken: String?
    var createdAt: Date

    static func generateInviteCode() -> String {
        InviteCode.generate()
    }
}
