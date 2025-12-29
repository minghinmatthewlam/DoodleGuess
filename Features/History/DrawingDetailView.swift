import PencilKit
import SwiftUI

struct DrawingDetailView: View {
    @EnvironmentObject var app: AppState

    let drawing: DrawingRecord?
    let drawingId: String?

    @State private var resolvedDrawing: DrawingRecord?
    @State private var image: UIImage?
    @State private var didLoad = false

    private struct LoadKey: Hashable {
        let drawingId: String?
        let authUserId: String?
        let isAuthLoading: Bool
        let isAuthenticated: Bool
        let latestReceivedId: String?
        let receivedCount: Int
        let sentCount: Int
    }

    init(drawing: DrawingRecord? = nil, drawingId: String? = nil) {
        self.drawing = drawing
        self.drawingId = drawingId
    }

    var body: some View {
        ZStack {
            BrandBackground()

            ScrollView {
                VStack(spacing: 20) {
                    if let image {
                        BrandCard {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                    } else if didLoad {
                        BrandCard {
                            VStack(spacing: 8) {
                                Text("Unable to load drawing")
                                    .font(Brand.text(16, weight: .semibold))
                                    .foregroundColor(Brand.ink)
                                Text("Open the app to refresh or try again later.")
                                    .font(Brand.text(13))
                                    .foregroundColor(Brand.inkSoft)
                            }
                            .padding(.vertical, 10)
                        }
                    } else {
                        ProgressView()
                    }

                    if let active = resolvedDrawing ?? drawing {
                        BrandCard {
                            VStack(alignment: .leading, spacing: 12) {
                                BrandPill(text: isSent(active) ? "SENT" : "RECEIVED")
                                Text(detailTitle(for: active))
                                    .font(Brand.text(18, weight: .semibold))
                                    .foregroundColor(Brand.ink)
                                Text(Formatters.detailDate.string(from: active.createdAt))
                                    .font(Brand.text(13))
                                    .foregroundColor(Brand.inkSoft)
                            }
                        }
                    }

                    NavigationLink {
                        CanvasScreen()
                    } label: {
                        Text("Draw Back")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
        }
        .task(id: LoadKey(
            drawingId: drawingId,
            authUserId: app.auth.currentUser?.id,
            isAuthLoading: app.auth.isLoading,
            isAuthenticated: app.auth.isAuthenticated,
            latestReceivedId: app.drawings.latestReceivedDrawing?.id,
            receivedCount: app.drawings.receivedDrawings.count,
            sentCount: app.drawings.sentDrawings.count
        )) {
            await load()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onDisappear {
            if app.deepLink.drawingId == drawingId {
                app.deepLink.drawingId = nil
            }
        }
    }

    private func download(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch { return nil }
    }

    @MainActor
    private func load() async {
        // NOTE: Deep links often cold-start the app before auth/pairing/listeners are ready.
        // We retry when auth or drawing state changes and show the widget cache immediately
        // to avoid a false "failed" state.
        didLoad = false
        resolvedDrawing = nil
        image = nil

        guard let drawingId, !drawingId.isEmpty else {
            didLoad = true
            return
        }

        await fallbackToWidgetCacheIfNeeded(drawingId: drawingId)

        if let drawing {
            resolvedDrawing = drawing
            await renderOrFallback(record: drawing, drawingId: drawingId)
            didLoad = true
            return
        }

        if let cached = app.drawings.receivedDrawings.first(where: { $0.id == drawingId })
            ?? app.drawings.sentDrawings.first(where: { $0.id == drawingId })
            ?? (app.drawings.latestReceivedDrawing?.id == drawingId ? app.drawings.latestReceivedDrawing : nil)
        {
            resolvedDrawing = cached
            await renderOrFallback(record: cached, drawingId: drawingId)
            didLoad = true
            return
        }

        if app.auth.isAuthenticated || !app.auth.isLoading {
            let fetched = await app.drawings.fetchDrawing(byId: drawingId)
            resolvedDrawing = fetched
            if let fetched {
                await renderOrFallback(record: fetched, drawingId: drawingId)
            } else {
                await fallbackToWidgetCacheIfNeeded(drawingId: drawingId)
            }
        } else {
            await fallbackToWidgetCacheIfNeeded(drawingId: drawingId)
        }

        didLoad = true
    }

    @MainActor
    private func renderOrFallback(record: DrawingRecord, drawingId: String) async {
        if let bytes = record.drawingBytes, let pk = try? PKDrawing(data: bytes) {
            image = DrawingRendering.renderSquare(drawing: pk, side: 1024, background: .white)
            return
        }
        if let url = record.imageUrl {
            image = await download(url)
            if image != nil { return }
        }
        await fallbackToWidgetCacheIfNeeded(drawingId: drawingId)
    }

    @MainActor
    private func fallbackToWidgetCacheIfNeeded(drawingId: String) async {
        guard image == nil else { return }
        let cached = SharedStorage.loadLatestDrawing()
        guard let cachedImage = cached.image else { return }
        if cached.metadata?.drawingId == drawingId || app.deepLink.drawingId == drawingId {
            image = cachedImage
        }
    }

    private func isSent(_ drawing: DrawingRecord) -> Bool {
        guard let me = app.auth.currentUser?.id else { return false }
        return drawing.fromUserId == me
    }

    private func detailTitle(for drawing: DrawingRecord) -> String {
        let raw = app.pairing.partner?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let partner = raw.isEmpty ? "Partner" : raw
        return isSent(drawing) ? "You sent this to \(partner)" : "\(partner) sent this to you"
    }
}
