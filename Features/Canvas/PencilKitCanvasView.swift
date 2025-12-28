import PencilKit
import SwiftUI

struct PencilKitCanvasView: UIViewRepresentable {
    @ObservedObject var vm: CanvasViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(vm: vm)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        vm.canvasView.delegate = context.coordinator
        return vm.canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        vm.applyTool()
    }
}

final class Coordinator: NSObject, PKCanvasViewDelegate {
    private let vm: CanvasViewModel

    init(vm: CanvasViewModel) {
        self.vm = vm
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        Task { @MainActor in
            vm.updateHasDrawing()
        }
    }
}
