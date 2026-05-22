import Photos
import SwiftUI

struct PhotoCardView: View {
    let group: PhotoGroup
    let assets: [PHAsset]
    @Binding var selectedAssetLocalIdentifier: String?
    @State private var previewAssetLocalIdentifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TabView(selection: $previewAssetLocalIdentifier) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    ZStack(alignment: .topTrailing) {
                        PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 900, height: 900), contentMode: .aspectFit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        if selectedAssetLocalIdentifier == asset.localIdentifier {
                            Label("残す候補", systemImage: "heart.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                                .padding(10)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAssetLocalIdentifier = asset.localIdentifier
                    }
                    .tag(Optional(asset.localIdentifier))
                }
            }
            .tabViewStyle(.page)
            .frame(maxWidth: .infinity)
            .aspectRatio(0.78, contentMode: .fit)
            Text(group.assetLocalIdentifiers.count > 1 ? "似た写真をまとめました。残したい1枚を選んでください。" : "少しずつ進めましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        ZStack(alignment: .topTrailing) {
                            PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 150, height: 150))
                                .frame(width: 66, height: 66)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            if selectedAssetLocalIdentifier == asset.localIdentifier {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .padding(5)
                                    .background(.tint)
                                    .clipShape(Circle())
                                    .padding(4)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedAssetLocalIdentifier == asset.localIdentifier ? Color.accentColor : Color.clear, lineWidth: 3)
                        }
                        .onTapGesture {
                            selectedAssetLocalIdentifier = asset.localIdentifier
                            previewAssetLocalIdentifier = asset.localIdentifier
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 12, y: 6)
        .onAppear {
            let fallback = group.representativeAssetLocalIdentifier ?? assets.first?.localIdentifier
            selectedAssetLocalIdentifier = selectedAssetLocalIdentifier ?? fallback
            previewAssetLocalIdentifier = selectedAssetLocalIdentifier
        }
        .onChange(of: group.groupId) {
            let fallback = group.representativeAssetLocalIdentifier ?? assets.first?.localIdentifier
            selectedAssetLocalIdentifier = fallback
            previewAssetLocalIdentifier = fallback
        }
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
