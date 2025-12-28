import SwiftUI

struct CanvasToolbar: View {
    @ObservedObject var vm: CanvasViewModel
    private let colors: [UIColor] = [.black, .systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple]

    var body: some View {
        HStack(spacing: 14) {
            Button { vm.isErasing = false; vm.applyTool() } label: {
                Image(systemName: "pencil").opacity(vm.isErasing ? 0.5 : 1)
            }

            Button { vm.isErasing = true; vm.applyTool() } label: {
                Image(systemName: "eraser").opacity(vm.isErasing ? 1 : 0.5)
            }

            ForEach(colors, id: \.self) { c in
                Button {
                    vm.selectedColor = c
                    vm.isErasing = false
                    vm.applyTool()
                } label: {
                    Circle()
                        .fill(Color(uiColor: c))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(
                            Color.primary.opacity(vm.selectedColor == c ? 0.8 : 0.2),
                            lineWidth: 2
                        ))
                }
            }

            Spacer()

            Button { vm.undo() } label: { Image(systemName: "arrow.uturn.backward") }
            Button { vm.clear() } label: { Image(systemName: "trash") }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }
}
