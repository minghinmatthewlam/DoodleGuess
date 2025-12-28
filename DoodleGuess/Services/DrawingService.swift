import Foundation
import UIKit
import PencilKit
import WidgetKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

@MainActor
final class DrawingService: ObservableObject {

    @Published var receivedDrawings: [DrawingRecord] = []
    @Published var sentDrawings: [DrawingRecord] = []
    @Published var latestReceivedDrawing: DrawingRecord?
    @Published var isSending = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    /// Send a drawing. Default path is bytes-only (offline-friendly).
    /// If uploadPNGToStorage = true, it also uploads a rendered PNG to Firebase Storage and saves imageUrl.
    func sendDrawing(
        pkDrawing: PKDrawing,
        renderedImage: UIImage,
        fromUserId: String,
        toUserId: String,
        pairId: String,
        uploadPNGToStorage: Bool = false
    ) async throws {
        isSending = true
        defer { isSending = false }

        let drawingId = UUID().uuidString
        let bytes = pkDrawing.dataRepresentation()

        var imageUrl: String? = nil

        if uploadPNGToStorage {
            guard let png = renderedImage.pngData() else { throw DrawingError.invalidImage }

            let ref = storage.reference().child("drawings/\(drawingId).png")
            let meta = StorageMetadata()
            meta.contentType = "image/png"

            _ = try await ref.putDataAsync(png, metadata: meta)
            let url = try await ref.downloadURL()
            imageUrl = url.absoluteString
        }

        let record = DrawingRecord(
            id: drawingId,
            pairId: pairId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            createdAt: Date(),
            drawingBytes: bytes,
            imageUrl: imageUrl
        )

        try await db.collection("drawings").document(drawingId).setData(from: record)
    }

    func startListeningForDrawings(userId: String, partnerName: String) {
        listener?.remove()

        listener = db.collection("drawings")
            .whereField("toUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error {
                    print("drawings listener error: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }

                Task { @MainActor in
                    let drawings = docs.compactMap { try? $0.data(as: DrawingRecord.self) }
                    self.receivedDrawings = drawings

                    if let latest = drawings.first {
                        self.latestReceivedDrawing = latest
                        await self.updateWidgetFromDrawing(latest, partnerName: partnerName)
                    }
                }
            }
    }

    func loadSentDrawings(userId: String) async {
        do {
            let snap = try await db.collection("drawings")
                .whereField("fromUserId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            self.sentDrawings = snap.documents.compactMap { try? $0.data(as: DrawingRecord.self) }
        } catch {
            print("loadSentDrawings error: \(error)")
        }
    }

    /// Update widget cache:
    /// - Prefer bytes (offline-friendly)
    /// - Fallback to imageUrl download if needed
    func updateWidgetFromDrawing(_ drawing: DrawingRecord, partnerName: String) async {
        let image: UIImage?

        if let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
            image = renderSquareForWidget(drawing: pk)
        } else if let urlStr = drawing.imageUrl, let downloaded = await downloadImage(from: urlStr) {
            image = downloaded
        } else {
            image = nil
        }

        guard let image else { return }

        let metadata = WidgetDrawingMetadata(
            partnerName: partnerName,
            timestamp: drawing.createdAt,
            drawingId: drawing.id ?? ""
        )

        SharedStorage.saveLatestDrawing(image: image, metadata: metadata)
        WidgetCenter.shared.reloadTimelines(ofKind: "DoodleWidget")
    }

    func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func renderSquareForWidget(drawing: PKDrawing) -> UIImage {
        let side: CGFloat = 512
        if drawing.strokes.isEmpty {
            return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            }
        }

        let bounds = drawing.bounds.insetBy(dx: -24, dy: -24)
        let scale = min(side / bounds.width, side / bounds.height)
        let ink = drawing.image(from: bounds, scale: scale)

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: side, height: side)).fill()
            let x = (side - ink.size.width) / 2
            let y = (side - ink.size.height) / 2
            ink.draw(in: CGRect(x: x, y: y, width: ink.size.width, height: ink.size.height))
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

enum DrawingError: LocalizedError {
    case invalidImage
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process drawing image."
        }
    }
}
