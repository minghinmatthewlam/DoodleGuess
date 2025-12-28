import SwiftUI
import PencilKit

struct HistoryView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var drawings: DrawingService

    var body: some View {
        List {
            Section("Received") {
                ForEach(drawings.receivedDrawings) { d in
                    NavigationLink {
                        DrawingDetailView(drawing: d)
                    } label: {
                        Text(d.id ?? "drawing")
                            .font(.caption)
                    }
                }
            }

            Section("Sent") {
                ForEach(drawings.sentDrawings) { d in
                    NavigationLink {
                        DrawingDetailView(drawing: d)
                    } label: {
                        Text(d.id ?? "drawing")
                            .font(.caption)
                    }
                }
            }
        }
        .task {
            if let me = auth.currentUser?.id {
                await drawings.loadSentDrawings(userId: me)
            }
        }
        .navigationTitle("History")
    }
}
