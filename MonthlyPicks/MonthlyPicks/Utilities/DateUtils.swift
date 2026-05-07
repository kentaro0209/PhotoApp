import Foundation

enum DateUtils {
    static let monthKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func monthKey(for date: Date) -> String {
        monthKeyFormatter.string(from: date)
    }

    static func title(for monthKey: String) -> String {
        guard let date = monthKeyFormatter.date(from: monthKey) else { return monthKey }
        return monthTitleFormatter.string(from: date)
    }

    static func monthInterval(for monthKey: String) -> DateInterval? {
        guard let start = monthKeyFormatter.date(from: monthKey),
              let end = Calendar.current.date(byAdding: .month, value: 1, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }
}
