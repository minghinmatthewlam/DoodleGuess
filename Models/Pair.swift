import Foundation

struct Pair: Codable, Identifiable {
    @DocumentID var id: String?
    var code: String
    var user1Id: String
    var user2Id: String?
    var createdAt: Date

    init(
        id: String?,
        code: String,
        user1Id: String,
        user2Id: String?,
        createdAt: Date
    ) {
        self._id = DocumentID(wrappedValue: id)
        self.code = code
        self.user1Id = user1Id
        self.user2Id = user2Id
        self.createdAt = createdAt
    }
}
