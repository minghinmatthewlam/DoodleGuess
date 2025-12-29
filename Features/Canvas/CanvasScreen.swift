import PencilKit
import SwiftUI

struct CanvasScreen: View {
    @EnvironmentObject var app: AppState

    @StateObject private var vm = CanvasViewModel()

    @State private var showingSent = false
    @State private var sendError: String?

    var body: some View {
        ZStack {
            BrandBackground()

            VStack(spacing: 16) {
                HStack {
                    BrandPill(text: "For \(partnerName())")
                    Spacer()
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Brand.ink.opacity(0.08), radius: 12, x: 0, y: 6)

                    PencilKitCanvasView(vm: vm)
                        .padding(10)
                }
                .frame(maxHeight: .infinity)

                CanvasToolbar(vm: vm)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if showingSent {
                SentToast(message: "Sent to \(partnerName())")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await send() }
                } label: {
                    if app.drawings.isSending {
                        ProgressView()
                    } else {
                        Text("Send")
                            .font(Brand.text(16, weight: .semibold))
                    }
                }
                .disabled(app.drawings.isSending || !vm.hasDrawing)
            }
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
        guard let me = app.auth.currentUser?.id else {
            sendError = "Not signed in."
            return
        }
        guard let partnerId = app.pairing.partner?.id else {
            sendError = "Not connected to a partner."
            return
        }
        guard let pairId = app.auth.currentUser?.pairId
            ?? app.pairing.partner?.pairId
        else {
            sendError = "Missing pair information."
            return
        }

        let pk = vm.canvasView.drawing
        let rendered = vm.renderSquareImage(side: 512)

        do {
            try await app.drawings.sendDrawing(
                pkDrawing: pk,
                renderedImage: rendered,
                fromUserId: me,
                toUserId: partnerId,
                pairId: pairId,
                uploadPNGToStorage: false
            )
            vm.clear()
            withAnimation(.spring()) {
                showingSent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut) {
                    showingSent = false
                }
            }
        } catch {
            sendError = error.localizedDescription
        }
    }

    private func partnerName() -> String {
        let name = app.pairing.partner?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Partner" : name
    }
}

struct SentToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Brand.accent2)
            Text(message)
                .font(Brand.text(14, weight: .semibold))
                .foregroundColor(Brand.ink)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.92))
                .overlay(Capsule().stroke(Brand.ink.opacity(0.08), lineWidth: 1))
                .shadow(color: Brand.ink.opacity(0.08), radius: 10, x: 0, y: 6)
        )
        .padding(.top, 8)
    }
}
