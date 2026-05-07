import Foundation

enum PhotoDecisionType: String, Codable, CaseIterable, Identifiable {
    case keep
    case reject
    case hold
    case unprocessed

    var id: String { rawValue }
}

struct PhotoDecision: Codable, Identifiable, Hashable {
    var id: String { assetLocalIdentifier }
    var assetLocalIdentifier: String
    var monthKey: String
    var decision: PhotoDecisionType
    var decidedAt: Date?
}
