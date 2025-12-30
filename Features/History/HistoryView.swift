import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var app: AppState
    @State private var filter: HistoryFilter = .all
    private let gridSize: GalleryGridSize = .medium

    var body: some View {
        ZStack {
            BrandBackground()

            GeometryReader { proxy in
                let layout = GalleryLayout(width: proxy.size.width - 40, gridSize: gridSize)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Gallery")
                            .font(Brand.display(30, weight: .bold))
                            .foregroundColor(Brand.ink)

                        VStack(spacing: 12) {
                            Picker("Filter", selection: $filter) {
                                ForEach(HistoryFilter.allCases, id: \.self) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: .infinity)
                        }

                        if filteredDrawings.isEmpty {
                            BrandCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(emptyStateTitle)
                                        .font(Brand.text(16, weight: .semibold))
                                        .foregroundColor(Brand.ink)
                                    Text(emptyStateSubtitle)
                                        .font(Brand.text(14))
                                        .foregroundColor(Brand.inkSoft)
                                }
                            }
                        } else {
                            LazyVGrid(columns: layout.columns, spacing: 14) {
                                ForEach(filteredDrawings, id: \.stableId) { drawing in
                                    navigationLink(for: drawing) {
                                        DrawingTile(
                                            drawing: drawing,
                                            isFavorite: isFavorite(drawing: drawing),
                                            side: layout.tileSide
                                        )
                                    }
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
    }

    private func navigationLink(for drawing: DrawingRecord, @ViewBuilder content: () -> some View) -> some View {
        NavigationLink {
            DrawingDetailView(drawings: filteredDrawings, initialDrawingId: drawing.stableId)
        } label: {
            content()
        }
        .buttonStyle(.plain)
    }

    private func isFavorite(drawing: DrawingRecord) -> Bool {
        app.favorites.isFavorite(drawing.stableId)
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
        case .favorites:
            return all.filter { app.favorites.isFavorite($0.stableId) }
        }
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

    private var emptyStateTitle: String {
        switch filter {
        case .favorites:
            "No favorites yet"
        default:
            "No drawings yet"
        }
    }

    private var emptyStateSubtitle: String {
        switch filter {
        case .favorites:
            "Tap the star on a doodle to save it here."
        default:
            "Your gallery will grow as you trade doodles."
        }
    }
}

enum HistoryFilter: String, CaseIterable {
    case all
    case received
    case sent
    case favorites

    var title: String {
        switch self {
        case .all: "All"
        case .received: "Received"
        case .sent: "Sent"
        case .favorites: "Favorites"
        }
    }
}

enum GalleryGridSize: String, CaseIterable {
    case small
    case medium
    case large

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }

    var systemImage: String {
        switch self {
        case .small: "square.grid.3x3"
        case .medium: "square.grid.2x2"
        case .large: "square"
        }
    }

    var columns: Int {
        switch self {
        case .small: 3
        case .medium: 2
        case .large: 1
        }
    }
}

struct DrawingTile: View {
    let drawing: DrawingRecord
    let isFavorite: Bool
    let side: CGFloat

    var body: some View {
        ZStack {
            DrawingPreviewImage(drawing: drawing, side: side, cornerRadius: 20)
        }
        .overlay(alignment: .topTrailing) {
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Brand.accent2)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .overlay(Circle().stroke(Brand.ink.opacity(0.08), lineWidth: 1))
                    )
                    .padding(8)
            }
        }
    }
}

private struct GalleryLayout {
    let width: CGFloat
    let gridSize: GalleryGridSize

    var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(tileSide), spacing: 14),
            count: max(1, gridSize.columns)
        )
    }

    var tileSide: CGFloat {
        let columnCount = CGFloat(max(1, gridSize.columns))
        let spacing = CGFloat(max(0, gridSize.columns - 1)) * 14
        let available = max(0, width - spacing)
        let proposed = available / columnCount
        return max(110, min(260, proposed))
    }

    var listThumb: CGFloat {
        max(72, min(90, tileSide * 0.55))
    }
}
