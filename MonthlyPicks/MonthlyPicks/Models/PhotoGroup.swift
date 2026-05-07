import Foundation

enum PhotoGroupType: String, Codable, CaseIterable {
    case burst
    case sameScene
    case sameLocation
    case similarVisual
    case single
}

struct PhotoGroup: Codable, Identifiable, Hashable {
    var id: String { groupId }
    var groupId: String
    var monthKey: String
    var assetLocalIdentifiers: [String]
    var representativeAssetLocalIdentifier: String?
    var groupType: PhotoGroupType
    var createdAt: Date
}
