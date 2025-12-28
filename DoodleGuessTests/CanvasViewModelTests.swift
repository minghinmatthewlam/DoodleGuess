@testable import DoodleGuess
import PencilKit
import XCTest

@MainActor
final class CanvasViewModelTests: XCTestCase {
    func testDrawingBytesRoundTrip() throws {
        let drawing = PKDrawing()
        let bytes = drawing.dataRepresentation()
        let decoded = try PKDrawing(data: bytes)
        XCTAssertEqual(drawing.strokes.count, decoded.strokes.count)
    }

    func testRenderSquareImageHasExpectedSize() {
        let vm = CanvasViewModel()
        vm.canvasView.drawing = PKDrawing()
        let image = vm.renderSquareImage(side: 256)
        XCTAssertEqual(image.size.width, 256)
        XCTAssertEqual(image.size.height, 256)
    }
}
