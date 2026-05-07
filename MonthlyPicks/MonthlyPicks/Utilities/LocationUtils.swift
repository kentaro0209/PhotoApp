import CoreLocation
import Foundation

enum LocationUtils {
    static func distanceMeters(lat1: Double?, lon1: Double?, lat2: Double?, lon2: Double?) -> Double? {
        guard let lat1, let lon1, let lat2, let lon2 else { return nil }
        let first = CLLocation(latitude: lat1, longitude: lon1)
        let second = CLLocation(latitude: lat2, longitude: lon2)
        return first.distance(from: second)
    }
}
