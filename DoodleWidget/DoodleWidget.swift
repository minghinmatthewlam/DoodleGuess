import SwiftUI
import UIKit
import WidgetKit

struct DoodleWidgetEntry: TimelineEntry {
    let date: Date
    let image: UIImage
    let partnerName: String
    let timestamp: Date?
    let drawingId: String?
}

struct DoodleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoodleWidgetEntry {
        loadEntry(context: context)
    }

    func getSnapshot(in context: Context, completion: @escaping (DoodleWidgetEntry) -> Void) {
        completion(loadEntry(context: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoodleWidgetEntry>) -> Void) {
        let entry = loadEntry(context: context)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry(context: Context) -> DoodleWidgetEntry {
        let (image, metadata) = SharedStorage.loadLatestDrawing()
        let fallback = UIImage(named: "starter_doodle") ?? UIImage()
        let baseImage = image ?? fallback
        let finalImage = resizedImage(
            baseImage,
            maxSide: maxSide(for: context.family),
            displayScale: UIScreen.main.scale
        )

        return DoodleWidgetEntry(
            date: Date(),
            image: finalImage,
            partnerName: metadata?.partnerName ?? "Partner",
            timestamp: metadata?.timestamp,
            drawingId: metadata?.drawingId
        )
    }

    private func maxSide(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall:
            320
        case .systemMedium:
            480
        default:
            480
        }
    }

    private func resizedImage(_ image: UIImage, maxSide: CGFloat, displayScale: CGFloat) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        if maxDimension <= maxSide {
            return image
        }

        let scale = maxSide / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = displayScale

        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
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
        .containerBackground(for: .widget) {
            Color.clear
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
