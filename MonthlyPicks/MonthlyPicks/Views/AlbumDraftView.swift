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
                    PhotoGridView(assets: assets, emptyTitle: "PDFに入れる写真がありません")
                        .padding(.horizontal)
                    NavigationLink {
                        PDFExportView(draft: draft)
                    } label: {
                        Label("PDFを作成", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
        }
        .navigationTitle("原稿プレビュー")
        .task { load() }
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
}
