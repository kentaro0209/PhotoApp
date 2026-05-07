import Photos
import UIKit

actor PhotoGroupingService {
    private let featureExtractor: PhotoFeatureExtractor
    private let similarityService: PhotoSimilarityService

    init(featureExtractor: PhotoFeatureExtractor, similarityService: PhotoSimilarityService) {
        self.featureExtractor = featureExtractor
        self.similarityService = similarityService
    }

    func groups(
        for assets: [PHAsset],
        monthKey: String,
        imageProvider: @escaping @Sendable (PHAsset) async -> UIImage?,
        progress: (@Sendable (Int, Int) async -> Void)? = nil
    ) async -> [PhotoGroup] {
        var features: [PhotoFeature] = []
        for (index, asset) in assets.enumerated() {
            let image = await imageProvider(asset)
            features.append(await featureExtractor.feature(for: asset, image: image))
            await progress?(index + 1, assets.count)
        }

        var groups: [[PhotoFeature]] = []
        for feature in features.sorted(by: { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) {
            if let index = groups.firstIndex(where: { group in
                group.contains { similarityService.score($0, feature) >= 0.75 }
            }) {
                groups[index].append(feature)
            } else {
                groups.append([feature])
            }
        }

        return groups.map { featureGroup in
            let representative = featureGroup.max(by: { $0.qualityScore < $1.qualityScore })?.assetLocalIdentifier
            let firstIdentifier = featureGroup.first?.assetLocalIdentifier ?? UUID().uuidString
            let stableSuffix = firstIdentifier
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "-", with: "_")
            return PhotoGroup(
                groupId: "\(monthKey)-\(stableSuffix)-\(featureGroup.count)",
                monthKey: monthKey,
                assetLocalIdentifiers: featureGroup.map(\.assetLocalIdentifier),
                representativeAssetLocalIdentifier: representative,
                groupType: featureGroup.count == 1 ? .single : .sameScene,
                createdAt: Date()
            )
        }
    }

    nonisolated func singleGroups(for assets: [PHAsset], monthKey: String) -> [PhotoGroup] {
        assets.map { asset in
            PhotoGroup(
                groupId: "\(monthKey)-\(asset.localIdentifier.replacingOccurrences(of: "/", with: "_"))-1",
                monthKey: monthKey,
                assetLocalIdentifiers: [asset.localIdentifier],
                representativeAssetLocalIdentifier: asset.localIdentifier,
                groupType: .single,
                createdAt: Date()
            )
        }
    }
}
