import CoreGraphics
import UIKit

enum ImageHashUtils {
    static func averageHash(from image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let width = 8
        let height = 8
        var pixels = [UInt8](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }
        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let average = pixels.map(Double.init).reduce(0, +) / Double(pixels.count)
        return pixels.map { Double($0) >= average ? "1" : "0" }.joined()
    }

    static func hammingDistance(_ lhs: String?, _ rhs: String?) -> Int? {
        guard let lhs, let rhs, lhs.count == rhs.count else { return nil }
        return zip(lhs, rhs).reduce(0) { $0 + ($1.0 == $1.1 ? 0 : 1) }
    }
}
