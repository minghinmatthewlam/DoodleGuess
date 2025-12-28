import SwiftUI
import PencilKit

struct PencilKitCanvasView: UIViewRepresentable {
    @ObservedObject var vm: CanvasViewModel

    func makeUIView(context: Context) -> PKCanvasView {
        vm.canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        vm.applyTool()
    }
}
