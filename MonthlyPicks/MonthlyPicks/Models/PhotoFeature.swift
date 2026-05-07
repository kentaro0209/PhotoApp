import Foundation

struct PhotoFeature: Codable, Identifiable, Hashable {
    var id: String { assetLocalIdentifier }
    var assetLocalIdentifier: String
    var monthKey: String
    var creationDate: Date?
    var latitude: Double?
    var longitude: Double?
    var perceptualHash: String?
    var brightness: Double?
    var sharpness: Double?
    var faceCount: Int?
    var aspectRatio: Double?
    var isScreenshot: Bool
    var analyzedAt: Date?

    var qualityScore: Double {
        let sharp = sharpness ?? 0.5
        let brightnessValue = brightness.map { 1.0 - min(1.0, abs($0 - 0.5) * 2.0) } ?? 0.5
        let facePresence = (faceCount ?? 0) > 0 ? 1.0 : 0.0
        return sharp * 0.4 + brightnessValue * 0.3 + facePresence * 0.2 + 0.1
    }
}
