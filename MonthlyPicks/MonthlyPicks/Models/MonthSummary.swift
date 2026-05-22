import Foundation

struct MonthSummary: Identifiable, Hashable {
    var id: String { monthKey }
    var monthKey: String
    var totalCount: Int
    var processedCount: Int
    var keepCount: Int
    var holdCount: Int
    var rejectCount: Int
    var targetCount: Int

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(processedCount) / Double(totalCount)
    }

    static func targetCount(for totalPhotos: Int) -> Int {
        min(totalPhotos, max(20, min(30, Int(Double(totalPhotos) * 0.10))))
    }
}
