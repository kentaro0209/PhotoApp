import Foundation

struct PhotoSimilarityService {
    func score(_ lhs: PhotoFeature, _ rhs: PhotoFeature) -> Double {
        timeSimilarity(lhs.creationDate, rhs.creationDate) * 0.30
        + locationSimilarity(lhs, rhs) * 0.20
        + visualSimilarity(lhs.perceptualHash, rhs.perceptualHash) * 0.50
    }

    func timeSimilarity(_ lhs: Date?, _ rhs: Date?) -> Double {
        guard let lhs, let rhs else { return 0 }
        let seconds = abs(lhs.timeIntervalSince(rhs))
        switch seconds {
        case 0...30: return 1.0
        case 30...180: return 0.8
        case 180...600: return 0.5
        default: return 0.0
        }
    }

    func locationSimilarity(_ lhs: PhotoFeature, _ rhs: PhotoFeature) -> Double {
        guard let distance = LocationUtils.distanceMeters(lat1: lhs.latitude, lon1: lhs.longitude, lat2: rhs.latitude, lon2: rhs.longitude) else { return 0 }
        switch distance {
        case 0...20: return 1.0
        case 20...100: return 0.8
        case 100...500: return 0.4
        default: return 0.0
        }
    }

    func visualSimilarity(_ lhs: String?, _ rhs: String?) -> Double {
        guard let distance = ImageHashUtils.hammingDistance(lhs, rhs) else { return 0.0 }
        switch distance {
        case 0...5: return 1.0
        case 6...12: return 0.8
        case 13...24: return 0.35
        default: return 0.0
        }
    }
}
