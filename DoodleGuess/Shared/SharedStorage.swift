import Foundation
import UIKit

/// App <-> Widget shared storage via App Group container.
/// - Stores image as a file (good practice; don't put large blobs in UserDefaults).
/// - Stores metadata as JSON (explicit, easy to debug).
enum SharedStorage {

    private static let imageFilename = "latest_drawing.png"
    private static let metadataFilename = "drawing_metadata.json"

    private static var imageURL: URL? {
        AppGroup.containerURL?.appendingPathComponent(imageFilename)
    }

    private static var metadataURL: URL? {
        AppGroup.containerURL?.appendingPathComponent(metadataFilename)
    }

    static func saveLatestDrawing(image: UIImage, metadata: WidgetDrawingMetadata) {
        guard let imageURL, let metadataURL else {
            print("App Group container not available - cannot save drawing")
            return
        }

        // Save image
        if let data = image.pngData() {
            do { try data.write(to: imageURL, options: [.atomic]) }
            catch { print("Failed to write image: \(error)") }
        }

        // Save metadata
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL, options: [.atomic])
        } catch {
            print("Failed to write metadata: \(error)")
        }
    }

    static func loadLatestDrawing() -> (image: UIImage?, metadata: WidgetDrawingMetadata?) {
        guard let imageURL, let metadataURL else {
            return (nil, nil)
        }

        let image = UIImage(contentsOfFile: imageURL.path)

        var metadata: WidgetDrawingMetadata?
        if let data = try? Data(contentsOf: metadataURL) {
            metadata = try? JSONDecoder().decode(WidgetDrawingMetadata.self, from: data)
        }
        return (image, metadata)
    }

    static func hasDrawing() -> Bool {
        guard let imageURL else { return false }
        return FileManager.default.fileExists(atPath: imageURL.path)
    }
}
