import WidgetKit
import SwiftUI

struct DoodleWidgetEntry: TimelineEntry {
    let date: Date
}

struct DoodleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DoodleWidgetEntry {
        DoodleWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (DoodleWidgetEntry) -> Void) {
        completion(DoodleWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoodleWidgetEntry>) -> Void) {
        let entry = DoodleWidgetEntry(date: Date())
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct DoodleWidgetEntryView: View {
    let entry: DoodleWidgetEntry

    var body: some View {
        ZStack {
            Color.white
            Text("DoodleGuess")
                .font(.caption)
        }
    }
}

struct DoodleWidget: Widget {
    let kind = "DoodleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoodleWidgetProvider()) { entry in
            DoodleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DoodleGuess")
        .description("Your partner's latest doodle.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct DoodleWidgetBundle: WidgetBundle {
    var body: some Widget {
        DoodleWidget()
    }
}
