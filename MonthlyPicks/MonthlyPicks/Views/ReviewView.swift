import Photos
import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var appState: AppState
    let monthKey: String
    @State private var selectedTab = 0
    @State private var keepAssets: [PHAsset] = []
    @State private var holdAssets: [PHAsset] = []

    var body: some View {
        ScrollView {
            Picker("表示", selection: $selectedTab) {
                Text("採用").tag(0)
                Text("保留").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if selectedTab == 0 {
                ReviewAssetGrid(
                    assets: keepAssets,
                    emptyTitle: "採用写真はまだありません",
                    primaryActionTitle: "採用解除",
                    primaryActionSystemImage: "minus.circle",
                    secondaryActionTitle: "表紙にする",
                    secondaryActionSystemImage: "star",
                    isCover: { appState.decisions.isCover($0.localIdentifier, monthKey: monthKey) },
                    primaryAction: { asset in
                        appState.decisions.updateDecision(forSelectedAssetLocalIdentifier: asset.localIdentifier, monthKey: monthKey, to: .hold)
                        load()
                    },
                    secondaryAction: { asset in
                        appState.decisions.setCover(asset.localIdentifier, monthKey: monthKey)
                        load()
                    }
                )
                .padding(.horizontal)
            } else {
                ReviewAssetGrid(
                    assets: holdAssets,
                    emptyTitle: "保留写真はありません",
                    primaryActionTitle: "採用へ移動",
                    primaryActionSystemImage: "heart.fill",
                    secondaryActionTitle: nil,
                    secondaryActionSystemImage: nil,
                    isCover: { _ in false },
                    primaryAction: { asset in
                        appState.decisions.updateDecision(forSelectedAssetLocalIdentifier: asset.localIdentifier, monthKey: monthKey, to: .keep)
                        load()
                    },
                    secondaryAction: nil
                )
                .padding(.horizontal)
            }
        }
        .navigationTitle("レビュー")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink("アルバム") {
                    AlbumExportView(monthKey: monthKey)
                }
                .disabled(keepAssets.isEmpty)
                Spacer()
                NavigationLink("PDF") {
                    LayoutSelectView(monthKey: monthKey)
                }
                .disabled(keepAssets.isEmpty)
            }
        }
        .task { load() }
        .onAppear { load() }
    }

    private func load() {
        keepAssets = appState.photoLibrary.assets(with: appState.decisions.keepIdentifiers(for: monthKey))
        holdAssets = appState.photoLibrary.assets(with: appState.decisions.holdIdentifiers(for: monthKey))
    }
}

private struct ReviewAssetGrid: View {
    let assets: [PHAsset]
    let emptyTitle: String
    let primaryActionTitle: String
    let primaryActionSystemImage: String
    let secondaryActionTitle: String?
    let secondaryActionSystemImage: String?
    let isCover: (PHAsset) -> Bool
    let primaryAction: (PHAsset) -> Void
    let secondaryAction: ((PHAsset) -> Void)?

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 12)]

    var body: some View {
        if assets.isEmpty {
            ContentUnavailableView(emptyTitle, systemImage: "photo")
                .padding(.top, 36)
        } else {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 360, height: 360))
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            if isCover(asset) {
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
                                primaryAction(asset)
                            } label: {
                                Label(primaryActionTitle, systemImage: primaryActionSystemImage)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            if let secondaryActionTitle, let secondaryActionSystemImage, let secondaryAction {
                                Button {
                                    secondaryAction(asset)
                                } label: {
                                    Label(secondaryActionTitle, systemImage: secondaryActionSystemImage)
                                        .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}
