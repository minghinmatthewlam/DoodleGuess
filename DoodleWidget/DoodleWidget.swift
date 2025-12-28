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
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> DoodleWidgetEntry {
        let (image, metadata) = SharedStorage.loadLatestDrawing()
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

struct DoodleWidgetEntryView: View {
    let entry: DoodleWidgetEntry

    var body: some View {
        ZStack {
            Image(uiImage: entry.image)
                .resizable()
                .scaledToFill()
                .clipped()

            VStack {
                Spacer()
                HStack {
                    Text(entry.partnerName)
                        .font(.caption2)
                        .lineLimit(1)

                    Spacer()

                    if let ts = entry.timestamp {
                        Text(RelativeDateTimeFormatter().localizedString(for: ts, relativeTo: Date()))
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
            }
        }
        .widgetURL(deepLinkURL(entry.drawingId))
    }

    private func deepLinkURL(_ drawingId: String?) -> URL? {
        if let drawingId {
            return URL(string: "doodleguess://drawing?id=\(drawingId)")
        }
        return URL(string: "doodleguess://open")
    }
}

struct DoodleWidget: Widget {
    let kind = "DoodleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoodleWidgetProvider()) { entry in
            DoodleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Partner's Drawing")
        .description("See your partner's latest doodle.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct DoodleWidgetBundle: WidgetBundle {
    var body: some Widget {
        DoodleWidget()
    }
}
