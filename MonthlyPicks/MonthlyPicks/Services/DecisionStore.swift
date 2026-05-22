import Combine
import Foundation

@MainActor
final class DecisionStore: ObservableObject {
    @Published private(set) var groupDecisions: [String: GroupDecision] = [:]
    @Published private(set) var selectedCoverByMonth: [String: String] = [:]
    @Published private(set) var groupsByMonth: [String: [PhotoGroup]] = [:]
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

    func group(for groupId: String, monthKey: String) -> PhotoGroup? {
        groupsByMonth[monthKey]?.first { $0.groupId == groupId }
    }

    func groupDecision(forSelectedAssetLocalIdentifier identifier: String, monthKey: String) -> GroupDecision? {
        groupDecisions.values.first {
            $0.monthKey == monthKey && $0.selectedAssetLocalIdentifier == identifier
        }
    }

    func groups(for monthKey: String, matching assetIdentifiers: [String]) -> [PhotoGroup]? {
        guard let stored = groupsByMonth[monthKey], !stored.isEmpty else { return nil }
        let currentIdentifiers = Set(assetIdentifiers)
        let filtered = stored.compactMap { group -> PhotoGroup? in
            let identifiers = group.assetLocalIdentifiers.filter { currentIdentifiers.contains($0) }
            guard !identifiers.isEmpty else { return nil }
            var updated = group
            updated.assetLocalIdentifiers = identifiers
            if let representative = group.representativeAssetLocalIdentifier, currentIdentifiers.contains(representative) {
                updated.representativeAssetLocalIdentifier = representative
            } else {
                updated.representativeAssetLocalIdentifier = identifiers.first
            }
            return updated
        }
        return filtered.isEmpty ? nil : filtered
    }

    func saveGroups(_ groups: [PhotoGroup], monthKey: String) {
        groupsByMonth[monthKey] = groups
        save()
    }

    func clearGroups(monthKey: String) {
        groupsByMonth.removeValue(forKey: monthKey)
        save()
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

    func updateDecision(forSelectedAssetLocalIdentifier identifier: String, monthKey: String, to decision: PhotoDecisionType) {
        guard let entry = groupDecisions.first(where: { _, value in
            value.monthKey == monthKey && value.selectedAssetLocalIdentifier == identifier
        }) else { return }

        var updated = entry.value
        updated.decision = decision
        updated.decidedAt = Date()
        groupDecisions[entry.key] = updated

        if selectedCoverByMonth[monthKey] == identifier && decision != .keep {
            selectedCoverByMonth.removeValue(forKey: monthKey)
        }

        save()
    }

    func updateSelectedAsset(groupId: String, monthKey: String, selectedAssetLocalIdentifier: String) {
        guard var updated = groupDecisions[groupId], updated.monthKey == monthKey else { return }
        updated.selectedAssetLocalIdentifier = selectedAssetLocalIdentifier
        updated.decision = .keep
        updated.decidedAt = Date()
        groupDecisions[groupId] = updated
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

    func isCover(_ identifier: String, monthKey: String) -> Bool {
        selectedCoverByMonth[monthKey] == identifier
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return }
        groupDecisions = Dictionary(uniqueKeysWithValues: payload.groupDecisions.map { ($0.groupId, $0) })
        selectedCoverByMonth = payload.selectedCoverByMonth
        groupsByMonth = payload.groupsByMonth ?? [:]
    }

    private func save() {
        let payload = Payload(groupDecisions: Array(groupDecisions.values), selectedCoverByMonth: selectedCoverByMonth, groupsByMonth: groupsByMonth)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }

    private struct Payload: Codable {
        var groupDecisions: [GroupDecision]
        var selectedCoverByMonth: [String: String]
        var groupsByMonth: [String: [PhotoGroup]]?
    }
}
