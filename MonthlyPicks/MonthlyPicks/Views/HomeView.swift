import Photos
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var summaries: [MonthSummary] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.photoLibrary.canRead {
                    List(summaries) { summary in
                        NavigationLink(value: summary.monthKey) {
                            MonthRow(summary: summary)
                        }
                    }
                    .refreshable { load() }
                } else {
                    ContentUnavailableView {
                        Label("写真へのアクセスが必要です", systemImage: "photo.on.rectangle")
                    } description: {
                        Text("月ごとの写真を表示し、代表写真を選ぶために使用します。")
                    } actions: {
                        Button("写真アクセスを許可") {
                            Task {
                                await appState.photoLibrary.requestAuthorization()
                                load()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Family Picks")
            .navigationDestination(for: String.self) { monthKey in
                SwipeView(monthKey: monthKey)
            }
            .toolbar {
                Button {
                    load()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .task {
                if appState.photoLibrary.canRead {
                    load()
                }
            }
        }
    }

    private func load() {
        isLoading = true
        summaries = appState.photoLibrary.fetchMonthSummaries(decisionStore: appState.decisions)
        isLoading = false
    }
}

private struct MonthRow: View {
    let summary: MonthSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DateUtils.title(for: summary.monthKey))
                    .font(.headline)
                Spacer()
                Text("\(summary.totalCount)枚")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: summary.progress)
            HStack {
                Text("見た写真 \(summary.processedCount) / \(summary.totalCount)")
                Spacer()
                Text("残す \(summary.keepCount) / 目安 \(summary.targetCount)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
