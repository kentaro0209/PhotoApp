import Photos
import SwiftUI

struct AlbumExportView: View {
    @EnvironmentObject private var appState: AppState
    let monthKey: String
    @State private var status: String?
    @State private var isExporting = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
            Text("Family Picks \(monthKey)")
                .font(.title3.bold())
            Text(status ?? "残した写真をiOS写真アプリ内のアルバムに追加します。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                Task { await export() }
            } label: {
                Label(isExporting ? "作成中" : "写真アルバムを作成", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting || appState.decisions.keepIdentifiers(for: monthKey).isEmpty)
        }
        .padding()
        .navigationTitle("写真アルバム")
    }

    private func export() async {
        isExporting = true
        defer { isExporting = false }
        let assets = appState.photoLibrary.assets(with: appState.decisions.keepIdentifiers(for: monthKey))
        do {
            try await appState.albumExport.exportAlbum(named: "Family Picks \(monthKey)", assets: assets)
            status = "写真アルバムに \(assets.count) 枚を追加しました。"
        } catch {
            status = error.localizedDescription
        }
    }
}
