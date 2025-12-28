import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        List {
            Section("Received") {
                ForEach(app.drawings.receivedDrawings) { d in
                    NavigationLink {
                        DrawingDetailView(drawing: d, drawingId: d.id)
                    } label: {
                        Text(d.id ?? "drawing")
                            .font(.caption)
                    }
                }
            }

            Section("Sent") {
                ForEach(app.drawings.sentDrawings) { d in
                    NavigationLink {
                        DrawingDetailView(drawing: d, drawingId: d.id)
                    } label: {
                        Text(d.id ?? "drawing")
                            .font(.caption)
                    }
                }
            }
        }
        .task {
            if let me = app.auth.currentUser?.id {
                await app.drawings.loadSentDrawings(userId: me)
            }
        }
        .navigationTitle("History")
    }
}
