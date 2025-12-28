import SwiftUI
import PencilKit

struct DrawingDetailView: View {
    let drawing: DrawingRecord

    @State private var image: UIImage?

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
            // Prefer bytes
            if let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
                image = renderFull(drawing: pk)
            } else if let url = drawing.imageUrl {
                image = await download(url)
            }
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func renderFull(drawing: PKDrawing) -> UIImage {
        // Render at higher resolution for full screen
        let side: CGFloat = 1024
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

    private func download(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch { return nil }
    }
}
