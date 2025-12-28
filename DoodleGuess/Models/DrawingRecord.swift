import Foundation
import FirebaseFirestoreSwift

struct DrawingRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var pairId: String
    var fromUserId: String
    var toUserId: String
    var createdAt: Date

    // Merged storage: bytes-first, URL optional.
    var drawingBytes: Data?
    var imageUrl: String?
}
