import Photos
import UIKit

struct PDFExportService {
    private let layoutEngine = LayoutEngine()

    func makePDF(draft: AlbumDraft, assets: [PHAsset], imageProvider: @escaping (PHAsset) async -> UIImage?) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(draft.title).pdf")
        var imagesByIdentifier: [String: UIImage] = [:]
        for asset in assets {
            imagesByIdentifier[asset.localIdentifier] = await imageProvider(asset)
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: PDFUtils.a4Landscape))
        let data = renderer.pdfData { context in
            drawCover(context: context, draft: draft, assets: assets, imagesByIdentifier: imagesByIdentifier)
            let pages = layoutEngine.pages(for: draft)
            for page in pages {
                context.beginPage()
                drawPhotoPage(context: context, page: page, assets: assets, imagesByIdentifier: imagesByIdentifier)
            }
        }
        try data.write(to: outputURL, options: [.atomic])
        return outputURL
    }

    private func drawCover(context: UIGraphicsPDFRendererContext, draft: AlbumDraft, assets: [PHAsset], imagesByIdentifier: [String: UIImage]) {
        context.beginPage()
        let page = CGRect(origin: .zero, size: PDFUtils.a4Landscape)
        UIColor.systemBackground.setFill()
        context.fill(page)
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 34), .foregroundColor: UIColor.label]
        draft.title.draw(at: CGPoint(x: 52, y: 48), withAttributes: titleAttributes)
        DateUtils.title(for: draft.monthKey).draw(at: CGPoint(x: 54, y: 94), withAttributes: [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.secondaryLabel])
        guard let coverId = draft.coverAssetLocalIdentifier,
              let asset = assets.first(where: { $0.localIdentifier == coverId }) ?? assets.first,
              let image = imagesByIdentifier[asset.localIdentifier] else { return }
        let rect = PDFUtils.aspectFitRect(imageSize: image.size, in: page.insetBy(dx: 80, dy: 145))
        image.draw(in: rect)
    }

    private func drawPhotoPage(context: UIGraphicsPDFRendererContext, page: AlbumPage, assets: [PHAsset], imagesByIdentifier: [String: UIImage]) {
        let bounds = CGRect(origin: .zero, size: PDFUtils.a4Landscape)
        UIColor.systemBackground.setFill()
        context.fill(bounds)
        let rects = layoutEngine.fourUpRects(in: bounds)
        for (index, identifier) in page.photoAssetLocalIdentifiers.enumerated() {
            guard index < rects.count,
                  let asset = assets.first(where: { $0.localIdentifier == identifier }),
                  let image = imagesByIdentifier[asset.localIdentifier] else { continue }
            let imageRect = PDFUtils.aspectFitRect(imageSize: image.size, in: rects[index])
            image.draw(in: imageRect)
            if let date = asset.creationDate {
                DateUtils.dayFormatter.string(from: date).draw(at: CGPoint(x: rects[index].minX, y: rects[index].maxY + 4), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.secondaryLabel])
            }
        }
    }
}
