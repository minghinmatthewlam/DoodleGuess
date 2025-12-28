import SwiftUI
import WidgetKit

/// Provides containerBackground for iOS 17+ while maintaining iOS 16 compatibility
struct ContainerBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.fill.tertiary, for: .widget)
        } else {
            content
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
                        // iOS 16-compatible relative time
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
        .modifier(ContainerBackgroundModifier())
    }

    private func deepLinkURL(_ drawingId: String?) -> URL? {
        if let drawingId {
            return URL(string: "doodleguess://drawing?id=\(drawingId)")
        }
        return URL(string: "doodleguess://open")
    }
}
