import WidgetKit
import SwiftUI

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
