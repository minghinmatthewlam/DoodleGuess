import Foundation

@MainActor
final class DeepLinkRouter: ObservableObject {
    @Published var drawingId: String?

    func handle(url: URL) {
        guard url.scheme == "doodleguess" else { return }

        if url.host == "drawing" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let raw = components?.queryItems?.first(where: { $0.name == "id" })?.value
            let cleaned = raw?
                .removingPercentEncoding?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            drawingId = (cleaned?.isEmpty == false) ? cleaned : nil
        } else {
            drawingId = nil
        }
    }
}
