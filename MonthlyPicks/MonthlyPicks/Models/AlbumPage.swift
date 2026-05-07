import Foundation

struct AlbumPage: Codable, Identifiable, Hashable {
    var id: String { pageId }
    var pageId: String
    var draftId: String
    var pageIndex: Int
    var layoutType: String
    var photoAssetLocalIdentifiers: [String]
    var caption: String?
}
