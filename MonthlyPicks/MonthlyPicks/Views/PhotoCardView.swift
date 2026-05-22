import Photos
import SwiftUI

struct PhotoCardView: View {
    let group: PhotoGroup
    let assets: [PHAsset]
    @Binding var selectedAssetLocalIdentifier: String?
    @Binding var comparisonComplete: Bool
    @State private var challengerIndex = 1
    @State private var challengerOffset: CGSize = .zero

    private var selectedAsset: PHAsset? {
        asset(for: selectedAssetLocalIdentifier)
    }

    private var challengerAsset: PHAsset? {
        guard assets.indices.contains(challengerIndex) else { return nil }
        let asset = assets[challengerIndex]
        return asset.localIdentifier == selectedAssetLocalIdentifier ? nil : asset
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(assets.count > 1 ? "似た写真を1枚ずつ比べて、残す候補を勝ち残らせます。" : "少しずつ進めましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if assets.count > 1, !comparisonComplete, let selectedAsset, let challengerAsset {
                ComparisonPane(title: "いまの残す候補", asset: selectedAsset, highlighted: true)
                ZStack(alignment: .topTrailing) {
                    PhotoThumbnailView(asset: challengerAsset, targetSize: CGSize(width: 900, height: 900), contentMode: .aspectFit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Label("比較中 \(min(challengerIndex + 1, assets.count)) / \(assets.count)", systemImage: "rectangle.stack")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(10)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(0.78, contentMode: .fit)
                .offset(challengerOffset)
                .rotationEffect(.degrees(Double(challengerOffset.width / 24)))
                .gesture(challengerDragGesture)
                .animation(.spring(response: 0.28, dampingFraction: 0.82), value: challengerOffset)

                HStack(spacing: 10) {
                    Button {
                        keepCurrentCandidate()
                    } label: {
                        Label("候補のまま", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        chooseChallenger()
                    } label: {
                        Label("こっちを候補に", systemImage: "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Text("右にスワイプでこの写真を候補に、左にスワイプで候補をそのまま進めます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let selectedAsset {
                ZStack(alignment: .topTrailing) {
                    PhotoThumbnailView(asset: selectedAsset, targetSize: CGSize(width: 900, height: 900), contentMode: .aspectFit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Label("この1枚を代表にします", systemImage: "heart.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(10)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(0.78, contentMode: .fit)
                Text("このグループの代表候補が決まりました。残す・見送る・あとでを選んでください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 12, y: 6)
        .onAppear {
            let fallback = group.representativeAssetLocalIdentifier ?? assets.first?.localIdentifier
            selectedAssetLocalIdentifier = selectedAssetLocalIdentifier ?? fallback
            resetComparison()
        }
        .onChange(of: group.groupId) {
            let fallback = group.representativeAssetLocalIdentifier ?? assets.first?.localIdentifier
            selectedAssetLocalIdentifier = fallback
            resetComparison()
        }
    }

    private func asset(for identifier: String?) -> PHAsset? {
        guard let identifier else { return nil }
        return assets.first { $0.localIdentifier == identifier }
    }

    private var challengerDragGesture: some Gesture {
        DragGesture()
            .onChanged { challengerOffset = $0.translation }
            .onEnded { value in
                if value.translation.width > 100 {
                    chooseChallenger()
                } else if value.translation.width < -100 {
                    keepCurrentCandidate()
                } else {
                    challengerOffset = .zero
                }
            }
    }

    private func resetComparison() {
        guard assets.count > 1 else {
            challengerIndex = 0
            comparisonComplete = true
            return
        }
        challengerIndex = firstChallengerIndex()
        comparisonComplete = challengerAsset == nil
        challengerOffset = .zero
    }

    private func firstChallengerIndex() -> Int {
        guard let selectedAssetLocalIdentifier else { return assets.indices.dropFirst().first ?? 0 }
        return assets.firstIndex { $0.localIdentifier != selectedAssetLocalIdentifier } ?? 0
    }

    private func advanceChallenge() {
        if let nextIndex = assets.indices.dropFirst(challengerIndex + 1).first(where: { assets[$0].localIdentifier != selectedAssetLocalIdentifier }) {
            challengerIndex = nextIndex
            challengerOffset = .zero
        } else {
            comparisonComplete = true
            challengerOffset = .zero
        }
    }

    private func keepCurrentCandidate() {
        challengerOffset = CGSize(width: -500, height: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            advanceChallenge()
        }
    }

    private func chooseChallenger() {
        guard let challengerAsset else { return }
        selectedAssetLocalIdentifier = challengerAsset.localIdentifier
        challengerOffset = CGSize(width: 500, height: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            advanceChallenge()
        }
    }
}

private struct ComparisonPane: View {
    let title: String
    let asset: PHAsset
    let highlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(highlighted ? Color.accentColor : Color.secondary)
            PhotoThumbnailView(asset: asset, targetSize: CGSize(width: 260, height: 180), contentMode: .aspectFit)
                .frame(height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(highlighted ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: highlighted ? 2 : 1)
                }
        }
        .frame(maxWidth: .infinity)
    }
}

struct PhotoThumbnailView: View {
    @EnvironmentObject private var appState: AppState
    let asset: PHAsset
    var targetSize: CGSize = CGSize(width: 240, height: 240)
    var contentMode: PHImageContentMode = .aspectFill
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Rectangle().fill(.secondary.opacity(0.12))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .clipped()
        .task(id: asset.localIdentifier) {
            appState.photoLibrary.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode) { loaded in
                image = loaded
            }
        }
    }
}
