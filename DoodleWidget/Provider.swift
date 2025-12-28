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

        // Never empty: use cached image or bundled fallback.
        let fallback = UIImage(named: "starter_doodle") ?? UIImage()
        let finalImage = image ?? fallback

        return DoodleWidgetEntry(
            date: Date(),
            image: finalImage,
            partnerName: metadata?.partnerName ?? "Partner",
            timestamp: metadata?.timestamp,
            drawingId: metadata?.drawingId
        )
    }
}
