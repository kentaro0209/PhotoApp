import Photos
import SwiftUI

struct AlbumDraftView: View {
    @EnvironmentObject private var appState: AppState
    let monthKey: String
    @State private var draft: AlbumDraft?
    @State private var assets: [PHAsset] = []

    var body: some View {
        ScrollView {
            if let draft {
                VStack(alignment: .leading, spacing: 18) {
                    Text(draft.title)
                        .font(.title2.bold())
                        .padding(.horizontal)
                    if let cover = assets.first(where: { $0.localIdentifier == draft.coverAssetLocalIdentifier }) ?? assets.first {
                        PhotoThumbnailView(asset: cover, targetSize: CGSize(width: 900, height: 520), contentMode: .aspectFit)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                    }
                    DraftAssetGrid(
                        assets: assets,
                        coverIdentifier: draft.coverAssetLocalIdentifier,
                        setCover: setCover,
                        remove: remove
                    )
                        .padding(.horizontal)
                    NavigationLink {
                        PDFExportView(draft: draft)
                    } label: {
                        Label("PDFを作成", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(assets.isEmpty)
                    .padding()
                }
            }
        }
        .navigationTitle("原稿プレビュー")
        .task { load() }
        .onAppear { load() }
    }

    private func load() {
        let identifiers = appState.decisions.keepIdentifiers(for: monthKey)
        assets = appState.photoLibrary.assets(with: identifiers)
        draft = appState.albumDraft.makeDraft(
            monthKey: monthKey,
            identifiers: identifiers,
            coverIdentifier: appState.decisions.selectedCoverByMonth[monthKey]
        )
    }

    private func setCover(_ asset: PHAsset) {
        guard var updated = draft else { return }
        updated.coverAssetLocalIdentifier = asset.localIdentifier
        updated.updatedAt = Date()
        draft = updated
    }

    private func remove(_ asset: PHAsset) {
        guard var updated = draft else { return }
        updated.photoAssetLocalIdentifiers.removeAll { $0 == asset.localIdentifier }
        if updated.coverAssetLocalIdentifier == asset.localIdentifier {
            updated.coverAssetLocalIdentifier = updated.photoAssetLocalIdentifiers.first
        }
        updated.updatedAt = Date()
        draft = updated
        assets = appState.photoLibrary.assets(with: updated.photoAssetLocalIdentifiers)
    }
}

private struct DraftAssetGrid: View {
    let assets: [PHAsset]
    let coverIdentifier: String?
    let setCover: (PHAsset) -> Void
    let remove: (PHAsset) -> Void

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 12)]

    var body: some View {
        if assets.isEmpty {
            ContentUnavailableView("PDFに入れる写真がありません", systemImage: "photo")
        } else {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 360, height: 360))
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            if coverIdentifier == asset.localIdentifier {
                                Label("表紙", systemImage: "star.fill")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                                    .padding(6)
                            }
                        }
                        HStack(spacing: 8) {
                            Button {
                                setCover(asset)
                            } label: {
                                Label("表紙", systemImage: "star")
                            }
                            .buttonStyle(.bordered)
                            .disabled(coverIdentifier == asset.localIdentifier)

                            Button(role: .destructive) {
                                remove(asset)
                            } label: {
                                Label("削除", systemImage: "trash")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.bordered)
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}
