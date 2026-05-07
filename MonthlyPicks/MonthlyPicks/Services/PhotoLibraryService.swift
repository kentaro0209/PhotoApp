import Combine
import Photos
import UIKit

@MainActor
final class PhotoLibraryService: ObservableObject {
    @Published private(set) var authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    private let imageManager = PHCachingImageManager()

    var canRead: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    func requestAuthorization() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func fetchMonthSummaries(decisionStore: DecisionStore) -> [MonthSummary] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: options)
        var counts: [String: Int] = [:]
        assets.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            counts[DateUtils.monthKey(for: date), default: 0] += 1
        }

        return counts.keys.sorted(by: >).map { monthKey in
            let total = counts[monthKey, default: 0]
            let groupDecisions = decisionStore.groupDecisions(for: monthKey)
            let processedIdentifiers = Set(groupDecisions
                .filter { $0.decision != .unprocessed }
                .compactMap(\.selectedAssetLocalIdentifier))
            return MonthSummary(
                monthKey: monthKey,
                totalCount: total,
                processedCount: min(total, processedIdentifiers.count),
                keepCount: groupDecisions.filter { $0.decision == .keep }.count,
                holdCount: groupDecisions.filter { $0.decision == .hold }.count,
                rejectCount: groupDecisions.filter { $0.decision == .reject }.count,
                targetCount: MonthSummary.targetCount(for: total)
            )
        }
    }

    func fetchAssets(monthKey: String) -> [PHAsset] {
        guard let interval = DateUtils.monthInterval(for: monthKey) else { return [] }
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
            PHAssetMediaType.image.rawValue,
            interval.start as NSDate,
            interval.end as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    func assets(with identifiers: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets.sorted {
            ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
        }
    }

    func requestImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
            completion(image)
        }
    }

    func requestImageAsync(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFit) async -> UIImage? {
        await withCheckedContinuation { continuation in
            requestImage(for: asset, targetSize: targetSize, contentMode: contentMode) { image in
                continuation.resume(returning: image)
            }
        }
    }
}
