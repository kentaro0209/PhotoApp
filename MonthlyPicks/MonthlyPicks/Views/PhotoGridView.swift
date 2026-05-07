import Photos
import SwiftUI

struct PhotoGridView: View {
    let assets: [PHAsset]
    let emptyTitle: String
    var onTap: (PHAsset) -> Void = { _ in }

    private let columns = [GridItem(.adaptive(minimum: 98), spacing: 8)]

    var body: some View {
        if assets.isEmpty {
            ContentUnavailableView(emptyTitle, systemImage: "photo")
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 240, height: 240))
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onTapGesture { onTap(asset) }
                }
            }
        }
    }
}
