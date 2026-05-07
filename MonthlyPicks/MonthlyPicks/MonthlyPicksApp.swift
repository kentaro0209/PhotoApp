import SwiftUI

@main
struct MonthlyPicksApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    let photoLibrary = PhotoLibraryService()
    let decisions = DecisionStore()
    let featureExtractor = PhotoFeatureExtractor()
    let similarity = PhotoSimilarityService()
    lazy var grouping = PhotoGroupingService(featureExtractor: featureExtractor, similarityService: similarity)
    let albumExport = AlbumExportService()
    let albumDraft = AlbumDraftService()
    let pdfExport = PDFExportService()
}
