import PencilKit
import UIKit

enum DrawingRendering {
    static func renderSquare(
        drawing: PKDrawing,
        side: CGFloat,
        background: UIColor = .white,
        padding: CGFloat = 24,
        allowUpscale: Bool = false
    ) -> UIImage {
        if drawing.strokes.isEmpty {
            return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
                background.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            }
        }

        var bounds = drawing.bounds
        bounds = bounds.insetBy(dx: -padding, dy: -padding)
        var scale = min(side / bounds.width, side / bounds.height)
        if !allowUpscale {
            scale = min(scale, 1)
        }
        let ink = drawing.image(from: bounds, scale: scale)

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            background.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: side, height: side)).fill()
            let x = (side - ink.size.width) / 2
            let y = (side - ink.size.height) / 2
            ink.draw(in: CGRect(x: x, y: y, width: ink.size.width, height: ink.size.height))
        }
    }

    static func renderComposite(
        drawing: PKDrawing,
        canvasSize: CGSize,
        outputSide: CGFloat,
        background: UIImage?
    ) -> UIImage {
        guard canvasSize.width > 0, canvasSize.height > 0 else {
            return renderSquare(drawing: drawing, side: outputSide, background: .white)
        }

        let outputSize = CGSize(width: outputSide, height: outputSide)
        let scale = outputSide / max(canvasSize.width, canvasSize.height)

        return UIGraphicsImageRenderer(size: outputSize).image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: outputSize)).fill()

            if let background {
                let rect = aspectFillRect(for: background.size, in: CGRect(origin: .zero, size: outputSize))
                background.draw(in: rect)
            }

            if !drawing.strokes.isEmpty {
                let drawingRect = CGRect(origin: .zero, size: canvasSize)
                let ink = drawing.image(from: drawingRect, scale: scale)
                let x = (outputSide - ink.size.width) / 2
                let y = (outputSide - ink.size.height) / 2
                ink.draw(in: CGRect(x: x, y: y, width: ink.size.width, height: ink.size.height))
            }
        }
    }

    private static func aspectFillRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = max(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2
        )
        return CGRect(origin: origin, size: size)
    }
}
