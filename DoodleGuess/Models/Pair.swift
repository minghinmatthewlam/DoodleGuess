import Foundation
import FirebaseFirestoreSwift

struct Pair: Codable, Identifiable {
    @DocumentID var id: String?
    var code: String
    var user1Id: String
    var user2Id: String?
    var createdAt: Date
}
