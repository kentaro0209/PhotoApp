import Photos
import SwiftUI

struct SwipeView: View {
    @EnvironmentObject private var appState: AppState
    let monthKey: String
    @State private var assets: [PHAsset] = []
    @State private var groups: [PhotoGroup] = []
    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero
    @State private var isLoading = true
    @State private var loadMessage = "写真を読み込んでいます"
    @State private var analysisProgress: Double?
    @State private var selectedAssetLocalIdentifier: String?

    private var currentGroup: PhotoGroup? {
        guard currentIndex < groups.count else { return nil }
        return groups[currentIndex]
    }

    private var summary: MonthSummary {
        appState.photoLibrary.fetchMonthSummaries(decisionStore: appState.decisions).first { $0.monthKey == monthKey }
        ?? MonthSummary(monthKey: monthKey, totalCount: assets.count, processedCount: currentIndex, keepCount: 0, holdCount: 0, rejectCount: 0, targetCount: MonthSummary.targetCount(for: assets.count))
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            Spacer(minLength: 0)
            if isLoading {
                VStack(spacing: 12) {
                    if let analysisProgress {
                        ProgressView(value: analysisProgress)
                    } else {
                        ProgressView()
                    }
                    Text(loadMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("すぐ始める") {
                        startWithSinglePhotoGroups()
                    }
                    .buttonStyle(.bordered)
                    .disabled(assets.isEmpty)
                }
                .padding()
            } else if let currentGroup {
                PhotoCardView(group: currentGroup, assets: assetsForCurrentGroup, selectedAssetLocalIdentifier: $selectedAssetLocalIdentifier)
                    .offset(offset)
                    .rotationEffect(.degrees(Double(offset.width / 24)))
                    .gesture(dragGesture)
                    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: offset)
                actionBar
            } else {
                ContentUnavailableView {
                    Label("今日はここまででOKです", systemImage: "checkmark.circle")
                } description: {
                    Text("残した写真を見返して、家族のフォトブックを作れます。")
                } actions: {
                    NavigationLink("見返す") {
                        ReviewView(monthKey: monthKey)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle(DateUtils.title(for: monthKey))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink("見返す") {
                ReviewView(monthKey: monthKey)
            }
            Button("まとめ直す") {
                Task { await reloadGroups() }
            }
            .disabled(isLoading)
        }
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DateUtils.title(for: monthKey))
                .font(.headline)
            ProgressView(value: summary.progress)
            HStack {
                Text("見た写真 \(summary.processedCount) / \(summary.totalCount)")
                Spacer()
                Text("残す \(summary.keepCount) / 目安 \(summary.targetCount)")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            if let currentGroup {
                Text("似た写真 \(selectedPhotoIndex(in: currentGroup)) / \(currentGroup.assetLocalIdentifiers.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("戻る", systemImage: "arrow.uturn.backward") { undo() }
            Button("見送る", systemImage: "xmark") { decide(.reject) }
            Button("あとで", systemImage: "clock") { decide(.hold) }
            Button("残す", systemImage: "heart.fill") { decide(.keep) }
                .buttonStyle(.borderedProminent)
        }
        .buttonStyle(.bordered)
    }

    private var assetsForCurrentGroup: [PHAsset] {
        guard let currentGroup else { return [] }
        return appState.photoLibrary.assets(with: currentGroup.assetLocalIdentifiers)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { offset = $0.translation }
            .onEnded { value in
                if value.translation.width > 120 {
                    decide(.keep)
                } else if value.translation.width < -120 {
                    decide(.reject)
                } else if value.translation.height > 120 {
                    decide(.hold)
                } else {
                    offset = .zero
                }
            }
    }

    private func selectedPhotoIndex(in group: PhotoGroup) -> Int {
        guard let selectedAssetLocalIdentifier,
              let index = group.assetLocalIdentifiers.firstIndex(of: selectedAssetLocalIdentifier) else {
            return 1
        }
        return index + 1
    }

    private func load() async {
        isLoading = true
        analysisProgress = nil
        assets = appState.photoLibrary.fetchAssets(monthKey: monthKey)
        let identifiers = assets.map(\.localIdentifier)
        if let storedGroups = appState.decisions.groups(for: monthKey, matching: identifiers) {
            groups = storedGroups
        } else {
            loadMessage = "似た写真をまとめています"
            let photoLibrary = appState.photoLibrary
            groups = await appState.grouping.groups(for: assets, monthKey: monthKey) { asset in
                await photoLibrary.requestImageAsync(for: asset, targetSize: CGSize(width: 180, height: 180))
            } progress: { completed, total in
                await MainActor.run {
                    analysisProgress = total == 0 ? nil : Double(completed) / Double(total)
                    loadMessage = "写真を解析しています \(completed) / \(total)"
                }
            }
            guard isLoading else { return }
            appState.decisions.saveGroups(groups, monthKey: monthKey)
        }
        groups = groups.filter { appState.decisions.decision(for: $0.groupId) == nil }
        currentIndex = 0
        selectedAssetLocalIdentifier = currentGroup?.representativeAssetLocalIdentifier ?? currentGroup?.assetLocalIdentifiers.first
        analysisProgress = nil
        isLoading = false
    }

    private func startWithSinglePhotoGroups() {
        groups = appState.grouping.singleGroups(for: assets, monthKey: monthKey)
        appState.decisions.saveGroups(groups, monthKey: monthKey)
        groups = groups.filter { appState.decisions.decision(for: $0.groupId) == nil }
        currentIndex = 0
        selectedAssetLocalIdentifier = currentGroup?.representativeAssetLocalIdentifier ?? currentGroup?.assetLocalIdentifiers.first
        analysisProgress = nil
        isLoading = false
    }

    private func reloadGroups() async {
        appState.decisions.clearGroups(monthKey: monthKey)
        await load()
    }

    private func decide(_ type: PhotoDecisionType) {
        guard let group = currentGroup else { return }
        let selected = selectedAssetLocalIdentifier ?? group.representativeAssetLocalIdentifier ?? group.assetLocalIdentifiers.first
        appState.decisions.record(group: group, decision: type, selectedAssetLocalIdentifier: selected)
        offset = type == .keep ? CGSize(width: 500, height: 0) : type == .reject ? CGSize(width: -500, height: 0) : CGSize(width: 0, height: 500)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            currentIndex += 1
            selectedAssetLocalIdentifier = currentGroup?.representativeAssetLocalIdentifier ?? currentGroup?.assetLocalIdentifiers.first
            offset = .zero
        }
    }

    private func undo() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        appState.decisions.undo(groupId: groups[currentIndex].groupId)
        selectedAssetLocalIdentifier = currentGroup?.representativeAssetLocalIdentifier ?? currentGroup?.assetLocalIdentifiers.first
    }
}
