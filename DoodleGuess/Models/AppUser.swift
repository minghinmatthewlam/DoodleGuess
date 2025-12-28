import Foundation
import FirebaseFirestoreSwift

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var partnerId: String?
    var pairId: String?          // active pair doc id (same as code)
    var inviteCode: String       // code others can use to join your pair
    var deviceToken: String?
    var createdAt: Date

    static func generateInviteCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
