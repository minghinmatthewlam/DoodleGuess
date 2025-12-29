import PencilKit
import SwiftUI

struct DrawingDetailView: View {
    @EnvironmentObject var app: AppState

    let drawing: DrawingRecord?
    let drawingId: String?

    @State private var resolvedDrawing: DrawingRecord?
    @State private var image: UIImage?
    @State private var didLoad = false

    init(drawing: DrawingRecord? = nil, drawingId: String? = nil) {
        self.drawing = drawing
        self.drawingId = drawingId
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(Color.white)
            } else if didLoad {
                VStack(spacing: 8) {
                    Text("Unable to load drawing")
                        .font(.headline)
                    Text("Open the app to refresh or try again later.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .task(id: drawingId) {
            didLoad = false
            image = nil
            resolvedDrawing = nil

            let activeDrawing: DrawingRecord?
            if let drawing {
                activeDrawing = drawing
            } else if let drawingId {
                let cached = app.drawings.receivedDrawings.first { $0.id == drawingId }
                    ?? app.drawings.sentDrawings.first { $0.id == drawingId }
                    ?? app.drawings.latestReceivedDrawing
                if let cached, cached.id == drawingId {
                    resolvedDrawing = cached
                    activeDrawing = cached
                } else {
                    let fetched = await app.drawings.fetchDrawing(byId: drawingId)
                    resolvedDrawing = fetched
                    activeDrawing = fetched
                }
            } else {
                activeDrawing = nil
            }

            guard let activeDrawing else {
                if let drawingId {
                    let cached = SharedStorage.loadLatestDrawing()
                    if cached.metadata?.drawingId == drawingId, let cachedImage = cached.image {
                        image = cachedImage
                    }
                }
                didLoad = true
                return
            }

            if let bytes = activeDrawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
                image = renderFull(drawing: pk)
            } else if let url = activeDrawing.imageUrl {
                image = await download(url)
            }
            didLoad = true
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if app.deepLink.drawingId == drawingId {
                app.deepLink.drawingId = nil
            }
        }
    }

    private func renderFull(drawing: PKDrawing) -> UIImage {
        let side: CGFloat = 1024
        var bounds = drawing.bounds.insetBy(dx: -24, dy: -24)
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

    private func download(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch { return nil }
    }
}
