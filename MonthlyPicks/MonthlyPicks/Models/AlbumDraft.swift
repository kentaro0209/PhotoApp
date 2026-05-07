import Foundation

enum AlbumPageSize: String, Codable, CaseIterable, Identifiable {
    case a4Landscape
    case squareBook
    case lPrint
    case squarePrint

    var id: String { rawValue }
}

enum AlbumLayoutStyle: String, Codable, CaseIterable, Identifiable {
    case fourPerPage
    case onePerPage
    case twoPerPage
    case collage

    var id: String { rawValue }
}

struct AlbumDraft: Codable, Identifiable, Hashable {
    var id: String { draftId }
    var draftId: String
    var monthKey: String
    var title: String
    var pageSize: AlbumPageSize
    var layoutStyle: AlbumLayoutStyle
    var photoAssetLocalIdentifiers: [String]
    var coverAssetLocalIdentifier: String?
    var createdAt: Date
    var updatedAt: Date
}
