import Foundation

enum PersonalRecordsPayloadMerger {
    typealias Snapshot = [String: Data]
    typealias Tombstones = [String: Set<String>]

    private struct CustomPayloadConfiguration {
        let customKey: String
        let valuesKey: String
        let historyKey: String
    }

    static let managedPayloadKeys = [
        "student_pr_barbell_values_v1",
        "student_pr_barbell_history_v1",
        "student_pr_barbell_custom_moves_v1",
        "student_pr_gymnastic_values_v1",
        "student_pr_gymnastic_history_v1",
        "student_pr_gymnastic_custom_items_v1",
        "student_pr_endurance_values_v1",
        "student_pr_endurance_history_v1",
        "student_pr_notables_values_v1",
        "student_pr_notables_history_v1",
        "student_pr_girls_values_v1",
        "student_pr_girls_history_v1",
        "student_pr_open_values_v1",
        "student_pr_open_history_v1",
        "student_pr_heroes_values_v1",
        "student_pr_heroes_history_v1",
        "student_pr_campeonatos_values_v1",
        "student_pr_campeonatos_history_v1",
        "student_pr_crossfit_games_values_v1",
        "student_pr_crossfit_games_history_v1"
    ]

    private static let numericValuesKeys: Set<String> = [
        "student_pr_barbell_values_v1",
        "student_pr_girls_values_v1"
    ]

    private static let customPayloadConfigurations = [
        CustomPayloadConfiguration(
            customKey: "student_pr_barbell_custom_moves_v1",
            valuesKey: "student_pr_barbell_values_v1",
            historyKey: "student_pr_barbell_history_v1"
        ),
        CustomPayloadConfiguration(
            customKey: "student_pr_gymnastic_custom_items_v1",
            valuesKey: "student_pr_gymnastic_values_v1",
            historyKey: "student_pr_gymnastic_history_v1"
        )
    ]

    static let customPayloadKeys = customPayloadConfigurations.map(\.customKey)

    static func mergeSnapshots(
        _ local: Snapshot,
        _ remote: Snapshot,
        tombstones: Tombstones
    ) -> Snapshot {
        var merged = Snapshot()

        for key in managedPayloadKeys {
            switch (local[key], remote[key]) {
            case let (localData?, remoteData?):
                merged[key] = mergePayload(key: key, local: localData, remote: remoteData)
            case let (localData?, nil):
                merged[key] = localData
            case let (nil, remoteData?):
                merged[key] = remoteData
            case (nil, nil):
                break
            }
        }

        return applying(tombstones: tombstones, to: merged)
    }

    static func mergePayload(key: String, local: Data, remote: Data) -> Data {
        guard local != remote else { return local }

        let localIsValid = hasExpectedJSONShape(for: key, data: local)
        let remoteIsValid = hasExpectedJSONShape(for: key, data: remote)
        if localIsValid != remoteIsValid {
            return localIsValid ? local : remote
        }

        if numericValuesKeys.contains(key) {
            return mergeValues(local, remote, numeric: true)
        }
        if key.hasSuffix("_values_v1") {
            return mergeValues(local, remote, numeric: false)
        }
        if key.hasSuffix("_history_v1") {
            return mergeHistories(local, remote)
        }
        if customPayloadConfigurations.contains(where: { $0.customKey == key }) {
            return mergeCustomItems(local, remote)
        }
        return deterministicallyPreferred(local, remote)
    }

    static func mergeTombstones(_ first: Tombstones, _ second: Tombstones) -> Tombstones {
        var merged = first
        for (key, values) in second {
            merged[key, default: []].formUnion(values)
        }
        return merged
    }

    static func mergeTombstones(_ first: [String: [String]], _ second: Tombstones) -> Tombstones {
        mergeTombstones(first.mapValues { Set($0) }, second)
    }

    static func tombstonesForFirestore(_ tombstones: Tombstones) -> [String: [String]] {
        tombstones.mapValues { $0.sorted() }
    }

    static func customTombstones(from previous: Snapshot, to current: Snapshot) -> Tombstones {
        var tombstones = Tombstones()

        for configuration in customPayloadConfigurations {
            let previousKeys = previous[configuration.customKey].map(customStorageKeys) ?? []
            let currentKeys = current[configuration.customKey].map(customStorageKeys) ?? []
            let deletedKeys = previousKeys.subtracting(currentKeys)
            if !deletedKeys.isEmpty {
                tombstones[configuration.customKey] = deletedKeys
            }
        }

        return tombstones
    }

    private static func mergeValues(_ local: Data, _ remote: Data, numeric: Bool) -> Data {
        guard let localMap = jsonObject(from: local) as? [String: Any],
              let remoteMap = jsonObject(from: remote) as? [String: Any]
        else {
            return deterministicallyPreferred(local, remote)
        }

        var merged = [String: Any]()
        for key in Set(localMap.keys).union(remoteMap.keys) {
            switch (localMap[key], remoteMap[key]) {
            case let (localValue?, remoteValue?):
                if numeric,
                   let localNumber = finiteNumber(localValue),
                   let remoteNumber = finiteNumber(remoteValue) {
                    merged[key] = max(localNumber, remoteNumber)
                } else if let localText = localValue as? String, let remoteText = remoteValue as? String {
                    merged[key] = localText <= remoteText ? localText : remoteText
                } else {
                    merged[key] = deterministicallyPreferred(localValue, remoteValue)
                }
            case let (localValue?, nil):
                merged[key] = localValue
            case let (nil, remoteValue?):
                merged[key] = remoteValue
            case (nil, nil):
                break
            }
        }

        return jsonData(from: merged) ?? deterministicallyPreferred(local, remote)
    }

    private static func mergeHistories(_ local: Data, _ remote: Data) -> Data {
        guard let localMap = historyMap(from: local),
              let remoteMap = historyMap(from: remote)
        else {
            return deterministicallyPreferred(local, remote)
        }

        var merged = [String: [Any]]()
        for key in Set(localMap.keys).union(remoteMap.keys) {
            var entriesByIdentifier = [String: Any]()
            for entry in (localMap[key] ?? []) + (remoteMap[key] ?? []) {
                let identifier = historyEntryIdentifier(for: entry)
                if let existing = entriesByIdentifier[identifier] {
                    entriesByIdentifier[identifier] = deterministicallyPreferred(existing, entry)
                } else {
                    entriesByIdentifier[identifier] = entry
                }
            }

            let entries = entriesByIdentifier.values.sorted(by: historyEntryComesBefore)
            merged[key] = entries
        }

        return jsonData(from: merged) ?? deterministicallyPreferred(local, remote)
    }

    private static func mergeCustomItems(_ local: Data, _ remote: Data) -> Data {
        guard let localItems = jsonObject(from: local) as? [Any],
              let remoteItems = jsonObject(from: remote) as? [Any]
        else {
            return deterministicallyPreferred(local, remote)
        }

        var uniqueItems = [String: Any]()
        for item in localItems + remoteItems {
            let identifier = customItemIdentifier(for: item)
            if let existing = uniqueItems[identifier] {
                uniqueItems[identifier] = deterministicallyPreferred(existing, item)
            } else {
                uniqueItems[identifier] = item
            }
        }

        let merged = uniqueItems.keys.sorted().compactMap { uniqueItems[$0] }
        return jsonData(from: merged) ?? deterministicallyPreferred(local, remote)
    }

    private static func applying(tombstones: Tombstones, to snapshot: Snapshot) -> Snapshot {
        guard !tombstones.isEmpty else { return snapshot }

        var result = snapshot
        for configuration in customPayloadConfigurations {
            guard let deletedKeys = tombstones[configuration.customKey], !deletedKeys.isEmpty else { continue }

            if let data = result[configuration.customKey],
               let items = jsonObject(from: data) as? [Any] {
                result[configuration.customKey] = jsonData(from: items.filter {
                    guard let item = $0 as? [String: Any],
                          let storageKey = item["storageKey"] as? String
                    else {
                        return true
                    }
                    return !deletedKeys.contains(storageKey)
                }) ?? data
            }

            for key in [configuration.valuesKey, configuration.historyKey] {
                guard let data = result[key],
                      var map = jsonObject(from: data) as? [String: Any]
                else {
                    continue
                }
                deletedKeys.forEach { map.removeValue(forKey: $0) }
                result[key] = jsonData(from: map) ?? data
            }
        }
        return result
    }

    private static func customStorageKeys(from data: Data) -> Set<String> {
        guard let items = jsonObject(from: data) as? [Any] else { return [] }
        return Set(items.compactMap { ($0 as? [String: Any])?["storageKey"] as? String })
    }

    private static func jsonObject(from data: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    private static func jsonData(from object: Any) -> Data? {
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        return try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private static func historyMap(from data: Data) -> [String: [Any]]? {
        guard let rawMap = jsonObject(from: data) as? [String: Any] else { return nil }
        var historyMap = [String: [Any]]()
        for (key, value) in rawMap {
            guard let entries = value as? [Any] else { return nil }
            historyMap[key] = entries
        }
        return historyMap
    }

    private static func hasExpectedJSONShape(for key: String, data: Data) -> Bool {
        if key.hasSuffix("_values_v1") {
            return jsonObject(from: data) is [String: Any]
        }
        if key.hasSuffix("_history_v1") {
            return historyMap(from: data) != nil
        }
        if customPayloadConfigurations.contains(where: { $0.customKey == key }) {
            return jsonObject(from: data) is [Any]
        }
        return false
    }

    private static func finiteNumber(_ value: Any) -> Double? {
        guard let number = value as? NSNumber else { return nil }
        let double = number.doubleValue
        return double.isFinite ? double : nil
    }

    private static func historyEntryComesBefore(_ first: Any, _ second: Any) -> Bool {
        let firstDate = (first as? [String: Any])?["createdAt"].flatMap(finiteNumber)
            ?? .greatestFiniteMagnitude
        let secondDate = (second as? [String: Any])?["createdAt"].flatMap(finiteNumber)
            ?? .greatestFiniteMagnitude
        if firstDate != secondDate {
            return firstDate < secondDate
        }

        let firstData = jsonData(from: first) ?? Data()
        let secondData = jsonData(from: second) ?? Data()
        return firstData.lexicographicallyPrecedes(secondData)
    }

    private static func historyEntryIdentifier(for entry: Any) -> String {
        if let dictionary = entry as? [String: Any],
           let id = dictionary["id"] as? String,
           !id.isEmpty {
            return "id:\(id)"
        }
        return "json:\((jsonData(from: entry) ?? Data()).base64EncodedString())"
    }

    private static func customItemIdentifier(for item: Any) -> String {
        if let dictionary = item as? [String: Any],
           let storageKey = dictionary["storageKey"] as? String,
           !storageKey.isEmpty {
            return "storage:\(storageKey)"
        }
        if let dictionary = item as? [String: Any],
           let id = dictionary["id"] as? String,
           !id.isEmpty {
            return "id:\(id)"
        }
        return "json:\((jsonData(from: item) ?? Data()).base64EncodedString())"
    }

    private static func deterministicallyPreferred(_ local: Data, _ remote: Data) -> Data {
        local.lexicographicallyPrecedes(remote) ? local : remote
    }

    private static func deterministicallyPreferred(_ local: Any, _ remote: Any) -> Any {
        let localData = jsonData(from: local) ?? Data()
        let remoteData = jsonData(from: remote) ?? Data()
        return localData.lexicographicallyPrecedes(remoteData) ? local : remote
    }
}
