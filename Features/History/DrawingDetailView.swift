import SwiftUI
import PencilKit

struct DrawingDetailView: View {
    let drawing: DrawingRecord?
    let drawingId: String?

    @State private var image: UIImage?

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
            } else {
                ProgressView()
            }
        }
        .task {
            guard let drawing else { return }

            if let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
                image = renderFull(drawing: pk)
            } else if let url = drawing.imageUrl {
                image = await download(url)
            }
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if drawing == nil {
                Text("Open the app to load this drawing")
                    .font(.footnote)
                    .foregroundColor(.secondary)
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
