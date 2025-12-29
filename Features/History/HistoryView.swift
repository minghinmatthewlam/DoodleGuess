import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var app: AppState
    @State private var filter: HistoryFilter = .all

    var body: some View {
        ZStack {
            BrandBackground()

            GeometryReader { proxy in
                let layout = HistoryLayout(width: proxy.size.width)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("History")
                            .font(Brand.display(30, weight: .bold))
                            .foregroundColor(Brand.ink)

                        Picker("Filter", selection: $filter) {
                            ForEach(HistoryFilter.allCases, id: \.self) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: .infinity)

                        if filteredDrawings.isEmpty {
                            BrandCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("No drawings yet")
                                        .font(Brand.text(16, weight: .semibold))
                                        .foregroundColor(Brand.ink)
                                    Text("Your history will grow as you trade doodles.")
                                        .font(Brand.text(14))
                                        .foregroundColor(Brand.inkSoft)
                                }
                            }
                        } else {
                            LazyVGrid(columns: layout.columns, spacing: 14) {
                                ForEach(filteredDrawings) { drawing in
                                    NavigationLink {
                                        DrawingDetailView(drawing: drawing, drawingId: drawing.id)
                                    } label: {
                                        DrawingTile(
                                            drawing: drawing,
                                            isSent: isSent(drawing: drawing),
                                            side: layout.tileSide
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .task {
            if let me = app.auth.currentUser?.id {
                await app.drawings.loadSentDrawings(userId: me)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func isSent(drawing: DrawingRecord) -> Bool {
        guard let me = app.auth.currentUser?.id else { return false }
        return drawing.fromUserId == me
    }

    private var filteredDrawings: [DrawingRecord] {
        let received = app.drawings.receivedDrawings.sorted { $0.createdAt > $1.createdAt }
        let sent = app.drawings.sentDrawings.sorted { $0.createdAt > $1.createdAt }
        let all = deduped((received + sent).sorted { $0.createdAt > $1.createdAt })

        switch filter {
        case .all:
            return all
        case .received:
            return received
        case .sent:
            return sent
        }
    }

    private func deduped(_ drawings: [DrawingRecord]) -> [DrawingRecord] {
        var seen = Set<String>()
        return drawings.filter { drawing in
            let key = drawing.id
                ?? "\(drawing.fromUserId)-\(drawing.toUserId)-\(drawing.createdAt.timeIntervalSince1970)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}

enum HistoryFilter: String, CaseIterable {
    case all
    case received
    case sent

    var title: String {
        switch self {
        case .all: "All"
        case .received: "Received"
        case .sent: "Sent"
        }
    }
}

struct DrawingTile: View {
    let drawing: DrawingRecord
    let isSent: Bool
    let side: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            DrawingPreviewImage(drawing: drawing, side: side, cornerRadius: 20)

            HStack(spacing: 6) {
                Text(isSent ? "Sent" : "Received")
                    .font(Brand.text(11, weight: .semibold))
                    .foregroundColor(Brand.ink)
                Text(Formatters.relative.localizedString(for: drawing.createdAt, relativeTo: Date()))
                    .font(Brand.text(10, weight: .medium))
                    .foregroundColor(Brand.inkSoft)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.85))
                    .overlay(Capsule().stroke(Brand.ink.opacity(0.08), lineWidth: 1))
            )
            .padding(10)
        }
    }
}

private struct HistoryLayout {
    let width: CGFloat

    var tileSide: CGFloat {
        let available = width - 54
        return max(120, min(180, available / 2))
    }

    var columns: [GridItem] {
        [GridItem(.fixed(tileSide), spacing: 14), GridItem(.fixed(tileSide), spacing: 14)]
    }
}
