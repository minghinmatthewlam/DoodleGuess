import Foundation
import PencilKit
import SwiftUI

struct DrawingPreviewImage: View {
    let drawing: DrawingRecord
    let side: CGFloat
    let cornerRadius: CGFloat

    @State private var image: UIImage?
    @State private var didLoad = false

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 250
        return cache
    }()

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if didLoad {
                placeholder
            } else {
                ProgressView()
            }
        }
        .frame(width: side, height: side)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: cacheKey) {
            didLoad = false
            if let cached = Self.cache.object(forKey: cacheKey) {
                image = cached
                didLoad = true
                return
            }
            image = nil
            await load()
            didLoad = true
        }
    }

    private var placeholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Brand.ink.opacity(0.5))
            Text("No preview")
                .font(Brand.text(12, weight: .medium))
                .foregroundColor(Brand.ink.opacity(0.5))
        }
    }

    private var cacheKey: NSString {
        "\(drawing.stableId)-\(Int(side))" as NSString
    }

    private func load() async {
        if let urlStr = drawing.imageUrl, let url = URL(string: urlStr) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                image = UIImage(data: data)
                if let image {
                    Self.cache.setObject(image, forKey: cacheKey)
                }
            } catch {
                image = nil
            }
        } else if let bytes = drawing.drawingBytes, let pk = try? PKDrawing(data: bytes) {
            image = DrawingRendering.renderSquare(drawing: pk, side: side, background: .white)
            if let image {
                Self.cache.setObject(image, forKey: cacheKey)
            }
        }
    }
}
