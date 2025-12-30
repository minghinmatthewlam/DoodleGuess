import SwiftUI

struct CanvasToolbar: View {
    @ObservedObject var vm: CanvasViewModel
    private let colors: [UIColor] = [.black, .systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple]
    private let widths: [CGFloat] = [4, 8, 14]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                toolButton(title: "Pen", systemImage: "pencil.tip") {
                    vm.inkStyle = .pen
                    vm.isErasing = false
                    vm.applyTool()
                }
                .opacity(vm.inkStyle == .pen && !vm.isErasing ? 1 : 0.5)

                toolButton(title: "Marker", systemImage: "highlighter") {
                    vm.inkStyle = .marker
                    vm.isErasing = false
                    vm.applyTool()
                }
                .opacity(vm.inkStyle == .marker && !vm.isErasing ? 1 : 0.5)

                toolButton(title: "Erase", systemImage: "eraser") {
                    vm.isErasing = true
                    vm.applyTool()
                }
                .opacity(vm.isErasing ? 1 : 0.5)

                Spacer()

                Button { vm.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                Button { vm.clear() } label: { Image(systemName: "trash") }
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
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .stroke(Brand.ink.opacity(vm.selectedColor == c ? 0.8 : 0.2), lineWidth: 2)
                            )
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    ForEach(widths, id: \.self) { width in
                        Button {
                            vm.strokeWidth = width
                            vm.isErasing = false
                            vm.applyTool()
                        } label: {
                            Circle()
                                .fill(Brand.ink)
                                .frame(width: width + 6, height: width + 6)
                                .opacity(vm.strokeWidth == width ? 1 : 0.4)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Brand.ink.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private func toolButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(Brand.text(13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.7))
            )
        }
    }
}
