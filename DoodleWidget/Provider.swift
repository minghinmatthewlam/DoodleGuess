import WidgetKit
import SwiftUI
import UIKit

struct DoodleWidgetEntry: TimelineEntry {
    let date: Date
    let image: UIImage
    let partnerName: String
    let timestamp: Date?
    let drawingId: String?
}

struct DoodleWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> DoodleWidgetEntry {
        DoodleWidgetEntry(
            date: Date(),
            image: UIImage(named: "starter_doodle") ?? UIImage(),
            partnerName: "Partner",
            timestamp: nil,
            drawingId: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DoodleWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoodleWidgetEntry>) -> Void) {
        let entry = loadEntry()

        // Request refresh periodically; iOS decides actual timing.
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> DoodleWidgetEntry {
        let (image, metadata) = SharedStorage.loadLatestDrawing()

        // Never empty: use cached image, bundled asset, or generated placeholder.
        let finalImage = image
            ?? UIImage(named: "starter_doodle")
            ?? generatePlaceholderImage()

        return DoodleWidgetEntry(
            date: Date(),
            image: finalImage,
            partnerName: metadata?.partnerName ?? "Partner",
            timestamp: metadata?.timestamp,
            drawingId: metadata?.drawingId
        )
    }

    /// Generates a simple placeholder image when no drawing or asset is available.
    private func generatePlaceholderImage() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            // Light gray background
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Draw a simple pencil icon hint
            let pencilPath = UIBezierPath()
            pencilPath.move(to: CGPoint(x: 100, y: 200))
            pencilPath.addLine(to: CGPoint(x: 200, y: 100))
            pencilPath.addLine(to: CGPoint(x: 210, y: 110))
            pencilPath.addLine(to: CGPoint(x: 110, y: 210))
            pencilPath.close()

            UIColor.systemGray3.setFill()
            pencilPath.fill()
        }
    }
}
