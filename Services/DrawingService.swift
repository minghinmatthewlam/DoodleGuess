import Foundation
import PencilKit
import UIKit
import WidgetKit

#if canImport(FirebaseFirestore) && canImport(FirebaseFirestoreSwift) && canImport(FirebaseStorage)
    import FirebaseFirestore
    import FirebaseFirestoreSwift
    import FirebaseStorage

    @MainActor
    final class DrawingService: ObservableObject {
        @Published var receivedDrawings: [DrawingRecord] = []
        @Published var sentDrawings: [DrawingRecord] = []
        @Published var latestReceivedDrawing: DrawingRecord?
        @Published var isSending = false

        private lazy var db = Firestore.firestore()
        private lazy var storage = Storage.storage()
        private var listener: ListenerRegistration?
        private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        func sendDrawing(
            pkDrawing: PKDrawing,
            renderedImage: UIImage,
            fromUserId: String,
            toUserId: String,
            pairId: String,
            uploadPNGToStorage: Bool = false
        ) async throws {
            guard !isRunningTests else { return }
            isSending = true
            defer { isSending = false }

            let drawingId = UUID().uuidString
            let bytes = pkDrawing.dataRepresentation()

            var imageUrl: String?
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

            try db.collection("drawings").document(drawingId).setData(from: record)
        }

        func startListeningForDrawings(userId: String, partnerName: String) {
            guard !isRunningTests else { return }
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

        func stopListeningForDrawings() {
            listener?.remove()
            listener = nil
            receivedDrawings = []
            latestReceivedDrawing = nil
        }

        func loadSentDrawings(userId: String) async {
            guard !isRunningTests else { return }
            do {
                let snap = try await db.collection("drawings")
                    .whereField("fromUserId", isEqualTo: userId)
                    .order(by: "createdAt", descending: true)
                    .getDocuments()

                sentDrawings = snap.documents.compactMap { try? $0.data(as: DrawingRecord.self) }
            } catch {
                print("loadSentDrawings error: \(error)")
            }
        }

        func fetchDrawing(byId drawingId: String) async -> DrawingRecord? {
            guard !isRunningTests else { return nil }
            do {
                let snap = try await db.collection("drawings").document(drawingId).getDocument()
                return try snap.data(as: DrawingRecord.self)
            } catch {
                print("fetchDrawing error: \(error)")
                return nil
            }
        }

        func updateWidgetFromDrawing(_ drawing: DrawingRecord, partnerName: String) async {
            let image: UIImage? = if let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
                renderSquareForWidget(drawing: pk)
            } else if let urlStr = drawing.imageUrl, let downloaded = await downloadImage(from: urlStr) {
                downloaded
            } else {
                nil
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
            DrawingRendering.renderSquare(drawing: drawing, side: 480, background: .white)
        }

        deinit { listener?.remove() }
    }

    enum DrawingError: LocalizedError {
        case invalidImage
        var errorDescription: String? {
            switch self {
            case .invalidImage: "Could not process drawing image."
            }
        }
    }

#else

    @MainActor
    final class DrawingService: ObservableObject {
        @Published var receivedDrawings: [DrawingRecord] = []
        @Published var sentDrawings: [DrawingRecord] = []
        @Published var latestReceivedDrawing: DrawingRecord?
        @Published var isSending = false

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

            let record = DrawingRecord(
                id: UUID().uuidString,
                pairId: pairId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                createdAt: Date(),
                drawingBytes: pkDrawing.dataRepresentation(),
                imageUrl: nil
            )

            receivedDrawings.insert(record, at: 0)
            latestReceivedDrawing = record
            await updateWidgetFromDrawing(record, partnerName: "Partner")
        }

        func startListeningForDrawings(userId: String, partnerName: String) {
            // No-op without Firebase.
        }

        func stopListeningForDrawings() {
            receivedDrawings = []
            latestReceivedDrawing = nil
        }

        func loadSentDrawings(userId: String) async {
            // No-op without Firebase.
        }

        func fetchDrawing(byId drawingId: String) async -> DrawingRecord? {
            receivedDrawings.first { $0.id == drawingId }
        }

        func updateWidgetFromDrawing(_ drawing: DrawingRecord, partnerName: String) async {
            guard let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) else { return }
            let image = renderSquareForWidget(drawing: pk)
            let metadata = WidgetDrawingMetadata(
                partnerName: partnerName,
                timestamp: drawing.createdAt,
                drawingId: drawing.id ?? ""
            )
            SharedStorage.saveLatestDrawing(image: image, metadata: metadata)
            WidgetCenter.shared.reloadTimelines(ofKind: "DoodleWidget")
        }

        private func renderSquareForWidget(drawing: PKDrawing) -> UIImage {
            DrawingRendering.renderSquare(drawing: drawing, side: 480, background: .white)
        }
    }

    enum DrawingError: LocalizedError {
        case invalidImage
        var errorDescription: String? {
            switch self {
            case .invalidImage: "Could not process drawing image."
            }
        }
    }

#endif
