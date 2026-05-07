import Photos
import SwiftUI

struct PhotoCardView: View {
    let group: PhotoGroup
    let assets: [PHAsset]
    @State private var previewAsset: PHAsset?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TabView(selection: $previewAsset) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 900, height: 900), contentMode: .aspectFit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .tag(Optional(asset))
                }
            }
            .tabViewStyle(.page)
            .frame(maxWidth: .infinity)
            .aspectRatio(0.78, contentMode: .fit)
            Text(group.assetLocalIdentifiers.count > 1 ? "この中から代表を1枚選んでください" : "少しずつ進めましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 150, height: 150))
                            .frame(width: 66, height: 66)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onTapGesture { previewAsset = asset }
                    }
                }
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 12, y: 6)
    }
}

struct PhotoThumbnailView: View {
    @EnvironmentObject private var appState: AppState
    let asset: PHAsset
    var targetSize: CGSize = CGSize(width: 240, height: 240)
    var contentMode: PHImageContentMode = .aspectFill
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Rectangle().fill(.secondary.opacity(0.12))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .clipped()
        .task(id: asset.localIdentifier) {
            appState.photoLibrary.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode) { loaded in
                image = loaded
            }
        }
    }
}
