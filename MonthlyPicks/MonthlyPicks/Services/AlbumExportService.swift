import Photos

struct AlbumExportService {
    func exportAlbum(named title: String, assets: [PHAsset]) async throws {
        let collection = try await findOrCreateAlbum(named: title)
        try await PHPhotoLibrary.shared().performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: collection) else { return }
            request.addAssets(assets as NSArray)
        }
    }

    private func findOrCreateAlbum(named title: String) async throws -> PHAssetCollection {
        if let existing = fetchAlbum(named: title) {
            return existing
        }

        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            placeholder = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title).placeholderForCreatedAssetCollection
        }

        guard let localIdentifier = placeholder?.localIdentifier else {
            throw NSError(domain: "MonthlyPicks", code: 1, userInfo: [NSLocalizedDescriptionKey: "アルバムを作成できませんでした。"])
        }

        let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let collection = result.firstObject else {
            throw NSError(domain: "MonthlyPicks", code: 2, userInfo: [NSLocalizedDescriptionKey: "作成したアルバムを取得できませんでした。"])
        }
        return collection
    }

    private func fetchAlbum(named title: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle == %@", title)
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options).firstObject
    }
}
