import CoreGraphics
import Foundation

struct LayoutEngine {
    func pages(for draft: AlbumDraft) -> [AlbumPage] {
        draft.photoAssetLocalIdentifiers.chunked(into: 4).enumerated().map { index, identifiers in
            AlbumPage(
                pageId: UUID().uuidString,
                draftId: draft.draftId,
                pageIndex: index + 1,
                layoutType: draft.layoutStyle.rawValue,
                photoAssetLocalIdentifiers: identifiers,
                caption: nil
            )
        }
    }

    func fourUpRects(in page: CGRect) -> [CGRect] {
        let margin: CGFloat = 44
        let gutter: CGFloat = 22
        let content = page.insetBy(dx: margin, dy: margin)
        let itemWidth = (content.width - gutter) / 2
        let itemHeight = (content.height - gutter) / 2
        return [
            CGRect(x: content.minX, y: content.minY, width: itemWidth, height: itemHeight),
            CGRect(x: content.minX + itemWidth + gutter, y: content.minY, width: itemWidth, height: itemHeight),
            CGRect(x: content.minX, y: content.minY + itemHeight + gutter, width: itemWidth, height: itemHeight),
            CGRect(x: content.minX + itemWidth + gutter, y: content.minY + itemHeight + gutter, width: itemWidth, height: itemHeight)
        ]
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
