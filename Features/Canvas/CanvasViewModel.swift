import Foundation
import PencilKit
import UIKit

@MainActor
final class CanvasViewModel: ObservableObject {
    let canvasView = PKCanvasView()

    enum InkStyle: String, CaseIterable {
        case pen = "Pen"
        case marker = "Marker"
    }

    @Published var selectedColor: UIColor = .black
    @Published var isErasing = false
    @Published var strokeWidth: CGFloat = 8
    @Published var inkStyle: InkStyle = .pen
    @Published var hasDrawing = false
    @Published var backgroundImage: UIImage?

    init() {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        applyTool()
        updateHasDrawing()
    }

    func applyTool() {
        if isErasing {
            canvasView.tool = PKEraserTool(.vector)
        } else {
            let toolType: PKInkingTool.InkType = (inkStyle == .marker) ? .marker : .pen
            let color = (inkStyle == .marker) ? selectedColor.withAlphaComponent(0.6) : selectedColor
            canvasView.tool = PKInkingTool(toolType, color: color, width: strokeWidth)
        }
    }

    func clear() {
        canvasView.drawing = PKDrawing()
        updateHasDrawing()
    }

    func clearBackground() {
        backgroundImage = nil
    }

    func undo() {
        canvasView.undoManager?.undo()
        updateHasDrawing()
    }

    func drawingBytes() -> Data {
        canvasView.drawing.dataRepresentation()
    }

    func updateHasDrawing() {
        hasDrawing = !canvasView.drawing.strokes.isEmpty
    }

    func renderSquareImage(side: CGFloat = 512, background: UIColor = .white) -> UIImage {
        DrawingRendering.renderSquare(drawing: canvasView.drawing, side: side, background: background)
    }

    func renderCompositeImage(side: CGFloat = 2048) -> UIImage {
        DrawingRendering.renderComposite(
            drawing: canvasView.drawing,
            canvasSize: canvasView.bounds.size,
            outputSide: side,
            background: backgroundImage
        )
    }
}
