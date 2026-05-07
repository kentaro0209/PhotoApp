import Photos
import SwiftUI

struct PDFExportView: View {
    @EnvironmentObject private var appState: AppState
    let draft: AlbumDraft
    @State private var pdfURL: URL?
    @State private var message = "フォトブックPDFを作成できます。"
    @State private var isWorking = false
    @State private var showingShare = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text(draft.title)
                .font(.title3.bold())
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                Task { await export() }
            } label: {
                Label(isWorking ? "作成中" : "フォトブックPDFを共有", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking || draft.photoAssetLocalIdentifiers.isEmpty)
        }
        .padding()
        .navigationTitle("フォトブックPDF")
        .sheet(isPresented: $showingShare) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
    }

    private func export() async {
        isWorking = true
        defer { isWorking = false }
        let assets = appState.photoLibrary.assets(with: draft.photoAssetLocalIdentifiers)
        do {
            let url = try await appState.pdfExport.makePDF(draft: draft, assets: assets) { asset in
                await appState.photoLibrary.requestImageAsync(for: asset, targetSize: CGSize(width: 1600, height: 1200), contentMode: .aspectFit)
            }
            pdfURL = url
            message = "フォトブックPDFを作成しました。保存・印刷・送信できます。"
            showingShare = true
        } catch {
            message = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
