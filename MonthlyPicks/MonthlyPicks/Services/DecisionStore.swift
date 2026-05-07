import Combine
import Foundation

@MainActor
final class DecisionStore: ObservableObject {
    @Published private(set) var groupDecisions: [String: GroupDecision] = [:]
    @Published private(set) var selectedCoverByMonth: [String: String] = [:]
    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = directory.appendingPathComponent("monthly-picks-decisions.json")
        load()
    }

    func groupDecisions(for monthKey: String) -> [GroupDecision] {
        groupDecisions.values.filter { $0.monthKey == monthKey }
    }

    func decision(for groupId: String) -> GroupDecision? {
        groupDecisions[groupId]
    }

    func record(group: PhotoGroup, decision: PhotoDecisionType, selectedAssetLocalIdentifier: String?) {
        groupDecisions[group.groupId] = GroupDecision(
            groupId: group.groupId,
            monthKey: group.monthKey,
            decision: decision,
            selectedAssetLocalIdentifier: selectedAssetLocalIdentifier,
            decidedAt: Date()
        )
        save()
    }

    func undo(groupId: String) {
        groupDecisions.removeValue(forKey: groupId)
        save()
    }

    func keepIdentifiers(for monthKey: String) -> [String] {
        groupDecisions(for: monthKey)
            .filter { $0.decision == .keep }
            .compactMap(\.selectedAssetLocalIdentifier)
    }

    func holdIdentifiers(for monthKey: String) -> [String] {
        groupDecisions(for: monthKey)
            .filter { $0.decision == .hold }
            .compactMap(\.selectedAssetLocalIdentifier)
    }

    func setCover(_ identifier: String, monthKey: String) {
        selectedCoverByMonth[monthKey] = identifier
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        groupDecisions = Dictionary(uniqueKeysWithValues: payload.groupDecisions.map { ($0.groupId, $0) })
        selectedCoverByMonth = payload.selectedCoverByMonth
    }

    private func save() {
        let payload = Payload(groupDecisions: Array(groupDecisions.values), selectedCoverByMonth: selectedCoverByMonth)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    private struct Payload: Codable {
        var groupDecisions: [GroupDecision]
        var selectedCoverByMonth: [String: String]
    }
}
