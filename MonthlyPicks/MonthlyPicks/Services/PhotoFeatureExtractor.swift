import Photos
import UIKit
import Vision

actor PhotoFeatureExtractor {
    private var cache: [String: PhotoFeature] = [:]

    func feature(for asset: PHAsset, image: UIImage?) async -> PhotoFeature {
        if let cached = cache[asset.localIdentifier] {
            return cached
        }

        let faces = image.flatMap(Self.faceCount) ?? 0
        let brightness = image.flatMap(Self.averageBrightness)
        let sharpness = image.flatMap(Self.simpleSharpness)
        let hash = image.flatMap(ImageHashUtils.averageHash)
        let feature = PhotoFeature(
            assetLocalIdentifier: asset.localIdentifier,
            monthKey: asset.creationDate.map(DateUtils.monthKey) ?? "",
            creationDate: asset.creationDate,
            latitude: asset.location?.coordinate.latitude,
            longitude: asset.location?.coordinate.longitude,
            perceptualHash: hash,
            brightness: brightness,
            sharpness: sharpness,
            faceCount: faces,
            aspectRatio: asset.pixelHeight == 0 ? nil : Double(asset.pixelWidth) / Double(asset.pixelHeight),
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            analyzedAt: Date()
        )
        cache[asset.localIdentifier] = feature
        return feature
    }

    private static func faceCount(in image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
        return request.results?.count ?? 0
    }

    private static func averageBrightness(in image: UIImage) -> Double? {
        guard let cgImage = image.cgImage else { return nil }
        let size = 16
        var pixels = [UInt8](repeating: 0, count: size * size)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: &pixels, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        return pixels.map(Double.init).reduce(0, +) / Double(pixels.count * 255)
    }

    private static func simpleSharpness(in image: UIImage) -> Double? {
        guard let cgImage = image.cgImage else { return nil }
        let size = 24
        var pixels = [UInt8](repeating: 0, count: size * size)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: &pixels, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        var total = 0.0
        for index in 1..<pixels.count {
            total += abs(Double(pixels[index]) - Double(pixels[index - 1]))
        }
        return min(1.0, total / Double(pixels.count) / 32.0)
    }
}
