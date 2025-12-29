import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ZStack {
            BrandBackground()

            GeometryReader { proxy in
                let layout = HomeLayout(width: proxy.size.width)
                ScrollView {
                    VStack(spacing: 22) {
                        header

                        latestCard(layout: layout)

                        actionRow

                        sentCard(layout: layout)

                        historyStrip(layout: layout)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(Brand.ink)
                }
            }
        }
        .task {
            if let me = app.auth.currentUser?.id {
                await app.drawings.loadSentDrawings(userId: me)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(Brand.display(34, weight: .bold))
                .foregroundColor(Brand.ink)

            HStack(spacing: 10) {
                BrandPill(text: "WIDGET FIRST")
                Text("From \(partnerName())")
                    .font(Brand.text(14, weight: .semibold))
                    .foregroundColor(Brand.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func latestCard(layout: HomeLayout) -> some View {
        Group {
            if let latest = app.drawings.latestReceivedDrawing {
                NavigationLink {
                    DrawingDetailView(drawing: latest)
                } label: {
                    DrawingHeroCard(
                        title: "Latest from \(partnerName())",
                        subtitle: relativeTime(latest.createdAt),
                        drawing: latest,
                        side: layout.heroSide
                    )
                }
                .buttonStyle(.plain)
            } else {
                BrandCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No doodles yet")
                            .font(Brand.text(18, weight: .semibold))
                            .foregroundColor(Brand.ink)
                        Text("Send the first one. It will appear on their widget in seconds.")
                            .font(Brand.text(14))
                            .foregroundColor(Brand.inkSoft)
                    }
                }
            }
        }
    }

    private var actionRow: some View {
        VStack(spacing: 12) {
            NavigationLink {
                CanvasScreen()
            } label: {
                Text("Draw Back")
            }
            .buttonStyle(PrimaryButtonStyle())

            NavigationLink {
                HistoryView()
            } label: {
                Text("Open Gallery")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func sentCard(layout: HomeLayout) -> some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Last sent")
                        .font(Brand.text(16, weight: .semibold))
                        .foregroundColor(Brand.ink)
                    Spacer()
                    if let drawing = app.drawings.sentDrawings.first {
                        Text(relativeTime(drawing.createdAt))
                            .font(Brand.text(12, weight: .medium))
                            .foregroundColor(Brand.inkSoft)
                    }
                }

                if let drawing = app.drawings.sentDrawings.first {
                    NavigationLink {
                        DrawingDetailView(drawing: drawing)
                    } label: {
                        HStack(spacing: 12) {
                            DrawingPreviewImage(drawing: drawing, side: layout.sentThumb, cornerRadius: 16)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Sent to \(partnerName())")
                                    .font(Brand.text(14, weight: .semibold))
                                    .foregroundColor(Brand.ink)
                                Text("Tap to view full size.")
                                    .font(Brand.text(12))
                                    .foregroundColor(Brand.inkSoft)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Nothing sent yet.")
                        .font(Brand.text(14))
                        .foregroundColor(Brand.inkSoft)
                }
            }
        }
    }

    private func historyStrip(layout: HomeLayout) -> some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent")
                        .font(Brand.text(16, weight: .semibold))
                        .foregroundColor(Brand.ink)
                    Spacer()
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Text("View gallery")
                            .font(Brand.text(13, weight: .semibold))
                            .foregroundColor(Brand.inkSoft)
                    }
                }

                if recentDrawings.isEmpty {
                    Text("Your first few doodles will show up here.")
                        .font(Brand.text(13))
                        .foregroundColor(Brand.inkSoft)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: layout.gridRows, spacing: 12) {
                            ForEach(recentDrawings) { drawing in
                                NavigationLink {
                                    DrawingDetailView(drawing: drawing)
                                } label: {
                                    DrawingPreviewImage(drawing: drawing, side: layout.recentThumb, cornerRadius: 18)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var recentDrawings: [DrawingRecord] {
        let all = app.drawings.receivedDrawings + app.drawings.sentDrawings
        let sorted = all.sorted { $0.createdAt > $1.createdAt }
        let unique = deduped(sorted)
        return Array(unique.prefix(8))
    }

    private func partnerName() -> String {
        let name = app.pairing.partner?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Partner" : name
    }

    private func relativeTime(_ date: Date) -> String {
        Formatters.relative.localizedString(for: date, relativeTo: Date())
    }

    private func deduped(_ drawings: [DrawingRecord]) -> [DrawingRecord] {
        var seen = Set<String>()
        return drawings.filter { drawing in
            let key = drawing.stableId
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}

struct DrawingHeroCard: View {
    let title: String
    let subtitle: String
    let drawing: DrawingRecord
    let side: CGFloat

    var body: some View {
        BrandCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(Brand.text(18, weight: .semibold))
                    .foregroundColor(Brand.ink)

                DrawingPreviewImage(drawing: drawing, side: side, cornerRadius: 22)
                    .frame(maxWidth: .infinity)

                Text(subtitle)
                    .font(Brand.text(13, weight: .medium))
                    .foregroundColor(Brand.inkSoft)
            }
        }
    }
}

private struct HomeLayout {
    let width: CGFloat

    var heroSide: CGFloat {
        let available = width - 80
        return max(220, min(280, available))
    }

    var recentThumb: CGFloat {
        let available = (width - 72) / 3
        return max(84, min(110, available))
    }

    var sentThumb: CGFloat {
        max(64, min(84, recentThumb - 12))
    }

    var gridRows: [GridItem] {
        [GridItem(.fixed(recentThumb), spacing: 12)]
    }
}
