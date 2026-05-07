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
                PhotoGridView(assets: keepAssets, emptyTitle: "採用写真はまだありません") { asset in
                    appState.decisions.setCover(asset.localIdentifier, monthKey: monthKey)
                }
                .padding()
            } else {
                PhotoGridView(assets: holdAssets, emptyTitle: "保留写真はありません")
                    .padding()
            }
        }
        .navigationTitle("レビュー")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink("アルバム") {
                    AlbumExportView(monthKey: monthKey)
                }
                Spacer()
                NavigationLink("PDF") {
                    LayoutSelectView(monthKey: monthKey)
                }
            }
        }
        .task { load() }
    }

    private func load() {
        keepAssets = appState.photoLibrary.assets(with: appState.decisions.keepIdentifiers(for: monthKey))
        holdAssets = appState.photoLibrary.assets(with: appState.decisions.holdIdentifiers(for: monthKey))
    }
}
