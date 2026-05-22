import Photos
import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var appState: AppState
    let monthKey: String
    @State private var selectedTab = 0
    @State private var keepAssets: [PHAsset] = []
    @State private var holdAssets: [PHAsset] = []
    @State private var reselectingGroup: PhotoGroup?

    var body: some View {
        ScrollView {
            Picker("表示", selection: $selectedTab) {
                Text("残す").tag(0)
                Text("あとで").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if selectedTab == 0 {
                ReviewAssetGrid(
                    assets: keepAssets,
                    emptyTitle: "残す写真はまだありません",
                    primaryActionTitle: "あとで見る",
                    primaryActionSystemImage: "minus.circle",
                    secondaryActionTitle: "表紙にする",
                    secondaryActionSystemImage: "star",
                    tertiaryActionTitle: "選び直す",
                    tertiaryActionSystemImage: "rectangle.stack",
                    isCover: { appState.decisions.isCover($0.localIdentifier, monthKey: monthKey) },
                    primaryAction: { asset in
                        appState.decisions.updateDecision(forSelectedAssetLocalIdentifier: asset.localIdentifier, monthKey: monthKey, to: .hold)
                        load()
                    },
                    secondaryAction: { asset in
                        appState.decisions.setCover(asset.localIdentifier, monthKey: monthKey)
                        load()
                    },
                    tertiaryAction: { asset in
                        guard let decision = appState.decisions.groupDecision(forSelectedAssetLocalIdentifier: asset.localIdentifier, monthKey: monthKey),
                              let group = appState.decisions.group(for: decision.groupId, monthKey: monthKey) else { return }
                        reselectingGroup = group
                    }
                )
                .padding(.horizontal)
            } else {
                ReviewAssetGrid(
                    assets: holdAssets,
                    emptyTitle: "あとで見る写真はありません",
                    primaryActionTitle: "残す",
                    primaryActionSystemImage: "heart.fill",
                    secondaryActionTitle: nil,
                    secondaryActionSystemImage: nil,
                    tertiaryActionTitle: nil,
                    tertiaryActionSystemImage: nil,
                    isCover: { _ in false },
                    primaryAction: { asset in
                        appState.decisions.updateDecision(forSelectedAssetLocalIdentifier: asset.localIdentifier, monthKey: monthKey, to: .keep)
                        load()
                    },
                    secondaryAction: nil,
                    tertiaryAction: nil
                )
                .padding(.horizontal)
            }
        }
        .navigationTitle("見返す")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink("写真アルバム") {
                    AlbumExportView(monthKey: monthKey)
                }
                .disabled(keepAssets.isEmpty)
                Spacer()
                NavigationLink("フォトブック") {
                    LayoutSelectView(monthKey: monthKey)
                }
                .disabled(keepAssets.isEmpty)
            }
        }
        .task { load() }
        .onAppear { load() }
        .sheet(item: $reselectingGroup) { group in
            ReselectPhotoView(monthKey: monthKey, group: group) {
                reselectingGroup = nil
                load()
            }
            .environmentObject(appState)
        }
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
    let tertiaryActionTitle: String?
    let tertiaryActionSystemImage: String?
    let isCover: (PHAsset) -> Bool
    let primaryAction: (PHAsset) -> Void
    let secondaryAction: ((PHAsset) -> Void)?
    let tertiaryAction: ((PHAsset) -> Void)?

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

                            if let tertiaryActionTitle, let tertiaryActionSystemImage, let tertiaryAction {
                                Button {
                                    tertiaryAction(asset)
                                } label: {
                                    Label(tertiaryActionTitle, systemImage: tertiaryActionSystemImage)
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

private struct ReselectPhotoView: View {
    @EnvironmentObject private var appState: AppState
    let monthKey: String
    let group: PhotoGroup
    let didUpdate: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(appState.photoLibrary.assets(with: group.assetLocalIdentifiers), id: \.localIdentifier) { asset in
                        VStack(spacing: 8) {
                            PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 340, height: 340))
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Button {
                                appState.decisions.updateSelectedAsset(groupId: group.groupId, monthKey: monthKey, selectedAssetLocalIdentifier: asset.localIdentifier)
                                didUpdate()
                                dismiss()
                            } label: {
                                Label("これを残す", systemImage: "heart.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("選び直す")
            .toolbar {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}
