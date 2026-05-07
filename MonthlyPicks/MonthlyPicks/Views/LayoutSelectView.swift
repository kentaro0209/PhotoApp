import SwiftUI

struct LayoutSelectView: View {
    let monthKey: String

    var body: some View {
        List {
            Section("MVP") {
                NavigationLink {
                    AlbumDraftView(monthKey: monthKey)
                } label: {
                    Label("A4横・1ページ4枚・表紙あり", systemImage: "doc.richtext")
                }
            }
            Section("将来拡張") {
                Label("正方形フォトブック", systemImage: "square")
                Label("L判プリント", systemImage: "photo")
                Label("ましかくプリント", systemImage: "square.grid.2x2")
                Label("1ページ1枚", systemImage: "rectangle.portrait")
                Label("1ページ2枚", systemImage: "rectangle.split.2x1")
                Label("コラージュ形式", systemImage: "square.grid.3x3")
            }
            .foregroundStyle(.secondary)
        }
        .navigationTitle("レイアウト")
    }
}
