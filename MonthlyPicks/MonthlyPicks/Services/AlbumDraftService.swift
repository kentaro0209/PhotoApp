import Foundation

struct AlbumDraftService {
    func makeDraft(monthKey: String, identifiers: [String], coverIdentifier: String?) -> AlbumDraft {
        AlbumDraft(
            draftId: UUID().uuidString,
            monthKey: monthKey,
            title: "Monthly Picks \(monthKey)",
            pageSize: .a4Landscape,
            layoutStyle: .fourPerPage,
            photoAssetLocalIdentifiers: identifiers,
            coverAssetLocalIdentifier: coverIdentifier ?? identifiers.first,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
