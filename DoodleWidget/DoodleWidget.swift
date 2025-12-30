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
    @Environment(\.widgetFamily) private var family
    let entry: DoodleWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Brand.backgroundTop, Brand.backgroundMid, Brand.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: family == .systemSmall ? 6 : 8) {
                HStack(spacing: 8) {
                    Text("Doodle Guess 🎨")
                        .font(.caption)
                        .foregroundColor(Brand.ink)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundColor(Brand.inkSoft)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Brand.ink.opacity(0.12), radius: 8, x: 0, y: 4)

                    Image(uiImage: entry.image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(6)
                }
                .aspectRatio(1, contentMode: .fit)

                if family != .systemSmall {
                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(Brand.inkSoft)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(10)
        }
        .containerBackground(for: .widget) { Color.clear }
        .widgetURL(deepLinkURL(entry.drawingId))
    }

    private func deepLinkURL(_ drawingId: String?) -> URL? {
        if let drawingId {
            return URL(string: "doodleguess://drawing?id=\(drawingId)")
        }
        return URL(string: "doodleguess://open")
    }

    private var statusText: String {
        if entry.drawingId == nil {
            return "Waiting for first doodle"
        }
        return "Latest from \(entry.partnerName)"
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
