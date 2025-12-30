import PencilKit
import PhotosUI
import SwiftUI

struct CanvasScreen: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = CanvasViewModel()

    @State private var showingSent = false
    @State private var sendError: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoError: String?

    var body: some View {
        ZStack {
            Brand.canvasBackground
                .ignoresSafeArea()

            GeometryReader { proxy in
                let canvasSide = max(220, proxy.size.width - 36)
                VStack(spacing: 16) {
                    header

                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Brand.ink.opacity(0.12), radius: 14, x: 0, y: 8)

                        ZStack {
                            if let background = vm.backgroundImage {
                                Image(uiImage: background)
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                            }

                            PencilKitCanvasView(vm: vm)
                                .padding(10)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .frame(width: canvasSide, height: canvasSide)

                    CanvasToolbar(
                        vm: vm,
                        selectedPhotoItem: $selectedPhotoItem,
                        hasBackground: vm.backgroundImage != nil,
                        onRemoveBackground: { vm.clearBackground() },
                        onUndo: { vm.undo() },
                        onClear: {
                            vm.clear()
                            vm.clearBackground()
                        }
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            if showingSent {
                SentToast(message: "Sent to \(partnerName())")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Error", isPresented: Binding(
            get: { sendError != nil },
            set: { if !$0 { sendError = nil } }
        )) {
            Button("OK") { sendError = nil }
        } message: {
            Text(sendError ?? "Something went wrong.")
        }
        .alert("Photo", isPresented: Binding(
            get: { photoError != nil },
            set: { if !$0 { photoError = nil } }
        )) {
            Button("OK") { photoError = nil }
        } message: {
            Text(photoError ?? "Unable to load that photo.")
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)
                    {
                        let scaled = ImageSizing.downscale(image, maxPixel: 2048)
                        await MainActor.run {
                            vm.backgroundImage = scaled
                            selectedPhotoItem = nil
                        }
                    } else {
                        await MainActor.run { photoError = "Unable to load that photo." }
                    }
                } catch {
                    await MainActor.run { photoError = error.localizedDescription }
                }
            }
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
        let hasBackground = vm.backgroundImage != nil
        let rendered = hasBackground ? vm.renderCompositeImage(side: 2048) : vm.renderSquareImage(side: 512)

        do {
            try await app.drawings.sendDrawing(
                pkDrawing: pk,
                renderedImage: rendered,
                fromUserId: me,
                toUserId: partnerId,
                pairId: pairId,
                uploadPNGToStorage: hasBackground
            )
            vm.clear()
            vm.clearBackground()
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

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Create Doodle")
                    .font(Brand.text(18, weight: .semibold))
                    .foregroundColor(.white)
                Text("For \(partnerName())")
                    .font(Brand.text(12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            Button {
                Task { await send() }
            } label: {
                if app.drawings.isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Send", systemImage: "paperplane.fill")
                        .font(Brand.text(13, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .disabled(app.drawings.isSending || !vm.hasDrawing)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .foregroundColor(Brand.accent)
            .opacity(app.drawings.isSending || !vm.hasDrawing ? 0.6 : 1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Brand.accent, Brand.accent2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: Brand.ink.opacity(0.2), radius: 12, x: 0, y: 8)
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
