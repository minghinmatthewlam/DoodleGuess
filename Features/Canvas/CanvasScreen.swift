import PencilKit
import SwiftUI

struct CanvasScreen: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var pairing: PairingService
    @EnvironmentObject var drawings: DrawingService

    @StateObject private var vm = CanvasViewModel()

    @State private var showingSent = false
    @State private var sendError: String?

    var body: some View {
        VStack(spacing: 0) {
            PencilKitCanvasView(vm: vm)
                .background(Color.white)

            CanvasToolbar(vm: vm)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await send() }
                } label: {
                    if drawings.isSending {
                        ProgressView()
                    } else {
                        Text("Send").fontWeight(.semibold)
                    }
                }
                .disabled(drawings.isSending || !vm.hasDrawing)
            }
        }
        .alert("Sent!", isPresented: $showingSent) {
            Button("OK") { vm.clear() }
        } message: {
            Text("Your drawing is on its way.")
        }
        .alert("Error", isPresented: Binding(
            get: { sendError != nil },
            set: { if !$0 { sendError = nil } }
        )) {
            Button("OK") { sendError = nil }
        } message: {
            Text(sendError ?? "Something went wrong.")
        }
    }

    private func send() async {
        guard let me = auth.currentUser?.id else {
            sendError = "Not signed in."
            return
        }
        guard let partnerId = pairing.partner?.id else {
            sendError = "Not connected to a partner."
            return
        }
        guard let pairId = auth.currentUser?.pairId ?? pairing.partner?.pairId ?? auth.currentUser?.pairId else {
            sendError = "Missing pair information."
            return
        }

        let pk = vm.canvasView.drawing
        let rendered = vm.renderSquareImage(side: 512)

        do {
            try await drawings.sendDrawing(
                pkDrawing: pk,
                renderedImage: rendered,
                fromUserId: me,
                toUserId: partnerId,
                pairId: pairId,
                uploadPNGToStorage: false
            )
            showingSent = true
        } catch {
            sendError = error.localizedDescription
        }
    }
}
