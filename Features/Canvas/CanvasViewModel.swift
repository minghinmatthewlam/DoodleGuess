import Foundation
import PencilKit
import UIKit

@MainActor
final class CanvasViewModel: ObservableObject {
    let canvasView = PKCanvasView()

    init() {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
    }

    func drawingBytes() -> Data {
        canvasView.drawing.dataRepresentation()
    }

    func renderSquareImage(side: CGFloat = 512, background: UIColor = .white) -> UIImage {
        let drawing = canvasView.drawing

        if drawing.strokes.isEmpty {
            return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
                background.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
            }
        }

        var bounds = drawing.bounds
        let pad: CGFloat = 24
        bounds = bounds.insetBy(dx: -pad, dy: -pad)

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
