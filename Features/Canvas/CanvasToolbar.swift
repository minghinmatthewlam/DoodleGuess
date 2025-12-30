import PhotosUI
import SwiftUI

struct CanvasToolbar: View {
    @ObservedObject var vm: CanvasViewModel
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let hasBackground: Bool
    let onRemoveBackground: () -> Void
    let onUndo: () -> Void
    let onClear: () -> Void

    private let colors: [UIColor] = [
        .black,
        .systemRed,
        .systemBlue,
        .systemGreen,
        .systemOrange,
        .systemPurple,
    ]
    private let widths: [CGFloat] = [4, 8, 14]

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    toolButton(
                        title: "Pen",
                        systemImage: "pencil.tip",
                        isActive: vm.inkStyle == .pen && !vm.isErasing
                    ) {
                        vm.inkStyle = .pen
                        vm.isErasing = false
                        vm.applyTool()
                    }

                    toolButton(
                        title: "Marker",
                        systemImage: "highlighter",
                        isActive: vm.inkStyle == .marker && !vm.isErasing
                    ) {
                        vm.inkStyle = .marker
                        vm.isErasing = false
                        vm.applyTool()
                    }

                    toolButton(title: "Erase", systemImage: "eraser", isActive: vm.isErasing) {
                        vm.isErasing = true
                        vm.applyTool()
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        toolSurface(isActive: false) {
                            toolLabel(title: "Photo", systemImage: "photo")
                        }
                    }

                    if hasBackground {
                        Button(action: onRemoveBackground) {
                            toolSurface(isActive: false) {
                                toolLabel(title: "Remove", systemImage: "photo.badge.minus")
                            }
                        }
                    }

                    Button(action: onUndo) {
                        toolSurface(isActive: false) {
                            toolLabel(title: "Undo", systemImage: "arrow.uturn.backward")
                        }
                    }

                    Button(action: onClear) {
                        toolSurface(isActive: false) {
                            toolLabel(title: "Clear", systemImage: "trash")
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach(colors, id: \.self) { c in
                    Button {
                        vm.selectedColor = c
                        vm.isErasing = false
                        vm.applyTool()
                    } label: {
                        Circle()
                            .fill(Color(uiColor: c))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(
                                        vm.selectedColor == c ? Brand.accent : Brand.ink.opacity(0.2),
                                        lineWidth: vm.selectedColor == c ? 2 : 1
                                    )
                            )
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    ForEach(widths, id: \.self) { width in
                        Button {
                            vm.strokeWidth = width
                            vm.isErasing = false
                            vm.applyTool()
                        } label: {
                            Circle()
                                .fill(Brand.ink)
                                .frame(width: width + 6, height: width + 6)
                                .opacity(vm.strokeWidth == width ? 1 : 0.35)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Brand.ink.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 8)
    }

    private func toolLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
                .font(Brand.text(12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(Brand.ink)
    }

    private func toolButton(
        title: String,
        systemImage: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            toolSurface(isActive: isActive) {
                toolLabel(title: title, systemImage: systemImage)
                    .foregroundColor(isActive ? .white : Brand.ink)
            }
        }
    }

    private func toolSurface(isActive: Bool, @ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isActive
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Brand.accent, Brand.accent2],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(Color.white.opacity(0.9))
                    )
            )
    }
}
