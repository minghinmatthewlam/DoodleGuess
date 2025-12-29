import PencilKit
import PhotosUI
import SwiftUI

struct CanvasScreen: View {
    @EnvironmentObject var app: AppState

    @StateObject private var vm = CanvasViewModel()

    @State private var showingSent = false
    @State private var sendError: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoError: String?

    var body: some View {
        ZStack {
            BrandBackground()

            GeometryReader { proxy in
                let canvasSide = max(220, proxy.size.width - 36)
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        BrandPill(text: "For \(partnerName())")
                        Spacer()

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            controlLabel(title: "Photo", systemImage: "photo")
                        }
                        .buttonStyle(.plain)

                        if vm.backgroundImage != nil {
                            Button {
                                vm.clearBackground()
                            } label: {
                                controlLabel(title: "Remove", systemImage: "photo.badge.minus")
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Brand.ink.opacity(0.08), radius: 12, x: 0, y: 6)

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

                    CanvasToolbar(vm: vm)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 12)
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

    private func controlLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
                .font(Brand.text(13, weight: .semibold))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
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
