@testable import DoodleGuess
import UIKit
import XCTest

final class SharedStorageTests: XCTestCase {
    func testSaveAndLoadRoundTripUsingTempDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        AppGroup.overrideURL = tempDir
        defer { AppGroup.overrideURL = nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16), format: format)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }

        let metadata = WidgetDrawingMetadata(partnerName: "Pat", timestamp: Date(), drawingId: "drawing-1")
        SharedStorage.saveLatestDrawing(image: image, metadata: metadata)

        let loaded = SharedStorage.loadLatestDrawing()
        XCTAssertNotNil(loaded.image)
        XCTAssertEqual(loaded.image?.size, image.size)
        XCTAssertEqual(loaded.metadata, metadata)
    }
}
