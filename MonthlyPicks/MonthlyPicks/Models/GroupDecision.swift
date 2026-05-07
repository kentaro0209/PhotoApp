import Foundation

struct GroupDecision: Codable, Identifiable, Hashable {
    var id: String { groupId }
    var groupId: String
    var monthKey: String
    var decision: PhotoDecisionType
    var selectedAssetLocalIdentifier: String?
    var decidedAt: Date?
}
