import UIKit

enum ImageSizing {
    static func downscale(_ image: UIImage, maxPixel: CGFloat) -> UIImage {
        let maxDimension = max(image.size.width, image.size.height)
        guard maxDimension > maxPixel else { return image }
        let scale = maxPixel / maxDimension
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
