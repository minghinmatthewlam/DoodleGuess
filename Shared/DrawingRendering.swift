import PencilKit
import UIKit

enum DrawingRendering {
    static func renderSquare(
        drawing: PKDrawing,
        side: CGFloat,
        background: UIColor = .white,
        padding: CGFloat = 24
    ) -> UIImage {
        if drawing.strokes.isEmpty {
            return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
                background.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            }
        }

        var bounds = drawing.bounds
        bounds = bounds.insetBy(dx: -padding, dy: -padding)
        let scale = min(side / bounds.width, side / bounds.height)
        let ink = drawing.image(from: bounds, scale: scale)

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            background.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: side, height: side)).fill()
            let x = (side - ink.size.width) / 2
            let y = (side - ink.size.height) / 2
            ink.draw(in: CGRect(x: x, y: y, width: ink.size.width, height: ink.size.height))
        }
    }
}
