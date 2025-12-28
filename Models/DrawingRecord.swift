import Foundation

#if canImport(FirebaseFirestoreSwift)
    import FirebaseFirestoreSwift
#endif

struct DrawingRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var pairId: String
    var fromUserId: String
    var toUserId: String
    var createdAt: Date

    var drawingBytes: Data?
    var imageUrl: String?

    init(
        id: String?,
        pairId: String,
        fromUserId: String,
        toUserId: String,
        createdAt: Date,
        drawingBytes: Data?,
        imageUrl: String?
    ) {
        _id = DocumentID(wrappedValue: id)
        self.pairId = pairId
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.createdAt = createdAt
        self.drawingBytes = drawingBytes
        self.imageUrl = imageUrl
    }
}
