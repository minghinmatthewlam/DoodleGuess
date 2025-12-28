import Foundation
import UIKit

enum SharedStorage {
    private static let imageFilename = "latest_drawing.png"
    private static let metadataFilename = "drawing_metadata.json"

    private static var imageURL: URL {
        AppGroup.containerURL.appendingPathComponent(imageFilename)
    }

    private static var metadataURL: URL {
        AppGroup.containerURL.appendingPathComponent(metadataFilename)
    }

    static func saveLatestDrawing(image: UIImage, metadata: WidgetDrawingMetadata) {
        if let data = image.pngData() {
            do {
                try data.write(to: imageURL, options: [.atomic])
            } catch {
                print("Failed to write image: \(error)")
            }
        }

        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL, options: [.atomic])
        } catch {
            print("Failed to write metadata: \(error)")
        }
    }

    static func loadLatestDrawing() -> (image: UIImage?, metadata: WidgetDrawingMetadata?) {
        let image = UIImage(contentsOfFile: imageURL.path)

        var metadata: WidgetDrawingMetadata?
        if let data = try? Data(contentsOf: metadataURL) {
            metadata = try? JSONDecoder().decode(WidgetDrawingMetadata.self, from: data)
        }

        return (image, metadata)
    }
}
