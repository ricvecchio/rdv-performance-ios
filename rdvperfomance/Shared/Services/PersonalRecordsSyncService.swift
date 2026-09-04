import Foundation
import FirebaseAuth

@MainActor
final class PersonalRecordsSyncService {
    static let shared = PersonalRecordsSyncService()

    private typealias Snapshot = PersonalRecordsPayloadMerger.Snapshot
    private typealias Tombstones = PersonalRecordsPayloadMerger.Tombstones

    private enum StorageKeys {
        static let ownerUID = "student_pr_sync_owner_uid_v1"
        static let pendingSnapshots = "student_pr_sync_pending_snapshots_v1"
        static let pendingTombstones = "student_pr_sync_pending_tombstones_v1"
        static let customBaselines = "student_pr_sync_custom_baselines_v1"
        static let unownedLegacySnapshot = "student_pr_sync_unowned_legacy_quarantine_v1"
    }

    private enum Retry {
        static let delays: [Duration] = [.seconds(1), .seconds(3), .seconds(8)]
    }

    private struct IdentifiedTask {
        let id: UUID
        let task: Task<Void, Never>
    }

    private let defaults = UserDefaults.standard
    private let firestoreRepository = FirestoreRepository.shared

    private var activeUID: String?
    private var synchronizationTasks: [String: IdentifiedTask] = [:]
    private var uploadTasks: [String: Task<Void, Never>] = [:]
    private var retryTasks: [String: IdentifiedTask] = [:]
    private var retryAttempts: [String: Int] = [:]
    private var synchronizedUIDs = Set<String>()
    private var revisions: [String: Int] = [:]

    private init() {}

    func prepareForAppLaunch() {
        let persistedOwner = ownerUID
        guard !persistedOwner.isEmpty else {
            quarantineUnownedSnapshotIfNeeded()
            clearManagedPayloads()
            return
        }

        // Do not expose a previously owned global cache while Firebase restores its session.
        // The explicit marker makes the per-UID pending copy safe to flush after authentication.
        persistPendingSnapshot(readSnapshot(), for: persistedOwner)
        establishCustomBaselineIfNeeded(from: readSnapshot(), for: persistedOwner)
        clearManagedPayloads()
        defaults.removeObject(forKey: StorageKeys.ownerUID)
    }

    func prepareForAuthenticatedUser(uid: String) {
        let cleanUID = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUID.isEmpty else { return }

        let persistedOwner = ownerUID
        if activeUID != cleanUID {
            cancelAllTasks()
        }

        if persistedOwner == cleanUID {
            activeUID = cleanUID
            establishCustomBaselineIfNeeded(from: readSnapshot(), for: cleanUID)
            return
        }

        if !persistedOwner.isEmpty {
            persistPendingSnapshot(readSnapshot(), for: persistedOwner)
            establishCustomBaselineIfNeeded(from: readSnapshot(), for: persistedOwner)
            clearManagedPayloads()
            defaults.removeObject(forKey: StorageKeys.ownerUID)
        } else {
            quarantineUnownedSnapshotIfNeeded()
            clearManagedPayloads()
        }

        activeUID = cleanUID
        synchronizedUIDs.remove(cleanUID)
        resetRetryState(for: cleanUID)
    }

    func synchronizeForAuthenticatedUser(uid: String) async {
        let cleanUID = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isCurrentAuthenticatedUser(cleanUID) else { return }

        if ownerUID == cleanUID,
           synchronizedUIDs.contains(cleanUID),
           !hasPendingChanges(for: cleanUID) {
            return
        }

        if let task = synchronizationTasks[cleanUID]?.task {
            await task.value
            return
        }

        let taskID = UUID()
        let task = Task { [weak self] in
            await self?.performInitialSynchronization(for: cleanUID)
            self?.finishSynchronizationTask(for: cleanUID, id: taskID)
        }
        synchronizationTasks[cleanUID] = IdentifiedTask(id: taskID, task: task)
        await task.value
    }

    func didMutateLocalRecords() {
        let uid = ownerUID
        if isCurrentAuthenticatedOwner(uid) {
            persistCurrentMutation(for: uid)
            scheduleUpload(for: uid)
            return
        }

        guard uid.isEmpty,
              let activeUID,
              isCurrentAuthenticatedUser(activeUID)
        else {
            return
        }

        // The unowned cache was cleared before this user became active, so this
        // snapshot can only contain a mutation made during the current session.
        persistPendingSnapshot(readSnapshot(), for: activeUID)
        revisions[activeUID, default: 0] += 1
        resetRetryState(for: activeUID)

        guard synchronizationTasks[activeUID] == nil else { return }
        Task { [weak self] in
            await self?.synchronizeForAuthenticatedUser(uid: activeUID)
        }
    }

    private func persistCurrentMutation(for uid: String) {
        let snapshot = readSnapshot()
        persistPendingSnapshot(snapshot, for: uid)

        let baseline = customBaseline(for: uid)
        let deletedCustomItems = PersonalRecordsPayloadMerger.customTombstones(
            from: baseline,
            to: snapshot
        )
        if !deletedCustomItems.isEmpty {
            persistPendingTombstones(deletedCustomItems, for: uid)
        }
        revisions[uid, default: 0] += 1
        resetRetryState(for: uid)
    }

    func handleLogout() {
        let persistedOwner = ownerUID
        cancelAllTasks()

        if !persistedOwner.isEmpty {
            persistPendingSnapshot(readSnapshot(), for: persistedOwner)
            establishCustomBaselineIfNeeded(from: readSnapshot(), for: persistedOwner)
        }

        activeUID = nil
        clearManagedPayloads()
        defaults.removeObject(forKey: StorageKeys.ownerUID)
        synchronizedUIDs.removeAll()
        revisions.removeAll()
    }

    private var ownerUID: String {
        (defaults.string(forKey: StorageKeys.ownerUID) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isCurrentAuthenticatedUser(_ uid: String) -> Bool {
        guard !uid.isEmpty, activeUID == uid else { return false }
        return Auth.auth().currentUser?.uid == uid
    }

    private func isCurrentAuthenticatedOwner(_ uid: String) -> Bool {
        ownerUID == uid && isCurrentAuthenticatedUser(uid)
    }

    private func trustedLocalSnapshot(for uid: String) -> Snapshot {
        let visibleSnapshot = ownerUID == uid ? readSnapshot() : [:]
        return PersonalRecordsPayloadMerger.mergeSnapshots(
            visibleSnapshot,
            pendingSnapshots()[uid] ?? [:],
            tombstones: pendingTombstones()[uid] ?? [:]
        )
    }

    private func scheduleUpload(for uid: String) {
        uploadTasks[uid]?.cancel()
        uploadTasks[uid] = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            await self?.performPendingUpload(for: uid)
        }
    }

    private func performInitialSynchronization(for uid: String) async {
        guard isCurrentAuthenticatedUser(uid) else { return }

        let revision = revisions[uid, default: 0]
        let localSnapshot = trustedLocalSnapshot(for: uid)
        let inferredTombstones = PersonalRecordsPayloadMerger.customTombstones(
            from: customBaseline(for: uid),
            to: localSnapshot
        )
        if !inferredTombstones.isEmpty {
            persistPendingTombstones(inferredTombstones, for: uid)
        }
        let localTombstones = pendingTombstones()[uid] ?? [:]

        do {
            let remoteDocument = try await firestoreRepository.getStudentPersonalRecords(uid: uid)
            guard isCurrentAuthenticatedUser(uid), !Task.isCancelled else { return }

            let remoteSnapshot = remoteDocument?.payloads ?? [:]
            let allTombstones = PersonalRecordsPayloadMerger.mergeTombstones(
                remoteDocument?.customTombstones ?? [:],
                localTombstones
            )
            let mergedSnapshot = PersonalRecordsPayloadMerger.mergeSnapshots(
                localSnapshot,
                remoteSnapshot,
                tombstones: allTombstones
            )
            let needsUpload = remoteDocument == nil
                || !localSnapshot.isEmpty
                || !localTombstones.isEmpty
                || remoteDocument?.requiresMigration == true
            let committedSnapshot: Snapshot

            if needsUpload {
                guard isCurrentAuthenticatedUser(uid), !Task.isCancelled else { return }
                let committedDocument = try await firestoreRepository.saveStudentPersonalRecords(
                    uid: uid,
                    payloads: localSnapshot,
                    customTombstones: PersonalRecordsPayloadMerger.tombstonesForFirestore(localTombstones)
                )
                guard isCurrentAuthenticatedUser(uid), !Task.isCancelled else { return }
                committedSnapshot = committedDocument.payloads
            } else {
                committedSnapshot = mergedSnapshot
            }

            completeSynchronization(
                for: uid,
                snapshot: committedSnapshot,
                revision: revision
            )
        } catch {
            scheduleRetry(for: uid)
        }
    }

    private func performPendingUpload(for uid: String) async {
        guard isCurrentAuthenticatedOwner(uid) else { return }

        let revision = revisions[uid, default: 0]
        let pendingSnapshot = pendingSnapshots()[uid] ?? readSnapshot()
        let localTombstones = PersonalRecordsPayloadMerger.mergeTombstones(
            pendingTombstones()[uid] ?? [:],
            PersonalRecordsPayloadMerger.customTombstones(
                from: customBaseline(for: uid),
                to: pendingSnapshot
            )
        )
        if !localTombstones.isEmpty {
            persistPendingTombstones(localTombstones, for: uid)
        }

        do {
            guard isCurrentAuthenticatedOwner(uid), !Task.isCancelled else { return }
            let committedDocument = try await firestoreRepository.saveStudentPersonalRecords(
                uid: uid,
                payloads: pendingSnapshot,
                customTombstones: PersonalRecordsPayloadMerger.tombstonesForFirestore(localTombstones)
            )
            guard isCurrentAuthenticatedOwner(uid), !Task.isCancelled else { return }

            completeSynchronization(
                for: uid,
                snapshot: committedDocument.payloads,
                revision: revision
            )
        } catch {
            scheduleRetry(for: uid)
        }
    }

    private func completeSynchronization(
        for uid: String,
        snapshot: Snapshot,
        revision: Int
    ) {
        guard isCurrentAuthenticatedUser(uid) else { return }

        let hasNewerLocalRevision = revisions[uid, default: 0] != revision
        if !hasNewerLocalRevision {
            writeSnapshot(snapshot)
            clearPendingChanges(for: uid)
        }

        // The marker is created only after a successful remote restore or UID-scoped write.
        defaults.set(uid, forKey: StorageKeys.ownerUID)
        persistCustomBaseline(from: snapshot, for: uid)
        synchronizedUIDs.insert(uid)
        resetRetryState(for: uid)

        if hasNewerLocalRevision {
            scheduleUpload(for: uid)
        }
    }

    private func scheduleRetry(for uid: String) {
        guard isCurrentAuthenticatedUser(uid),
              retryTasks[uid] == nil,
              Retry.delays.indices.contains(retryAttempts[uid, default: 0])
        else {
            return
        }

        let delay = Retry.delays[retryAttempts[uid, default: 0]]
        retryAttempts[uid, default: 0] += 1
        let taskID = UUID()
        let task = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }

            await self?.runScheduledRetry(for: uid, id: taskID)
        }
        retryTasks[uid] = IdentifiedTask(id: taskID, task: task)
    }

    private func runScheduledRetry(for uid: String, id: UUID) async {
        guard retryTasks[uid]?.id == id else { return }
        retryTasks.removeValue(forKey: uid)

        guard isCurrentAuthenticatedUser(uid), !Task.isCancelled else { return }
        await synchronizeForAuthenticatedUser(uid: uid)
    }

    private func finishSynchronizationTask(for uid: String, id: UUID) {
        guard synchronizationTasks[uid]?.id == id else { return }
        synchronizationTasks.removeValue(forKey: uid)
    }

    private func resetRetryState(for uid: String) {
        retryTasks[uid]?.task.cancel()
        retryTasks.removeValue(forKey: uid)
        retryAttempts.removeValue(forKey: uid)
    }

    private func cancelAllTasks() {
        uploadTasks.values.forEach { $0.cancel() }
        synchronizationTasks.values.forEach { $0.task.cancel() }
        retryTasks.values.forEach { $0.task.cancel() }
        uploadTasks.removeAll()
        synchronizationTasks.removeAll()
        retryTasks.removeAll()
        retryAttempts.removeAll()
    }

    private func readSnapshot() -> Snapshot {
        PersonalRecordsPayloadMerger.managedPayloadKeys.reduce(into: [:]) { snapshot, key in
            if let data = defaults.data(forKey: key) {
                snapshot[key] = data
            }
        }
    }

    private func writeSnapshot(_ snapshot: Snapshot) {
        for key in PersonalRecordsPayloadMerger.managedPayloadKeys {
            if let data = snapshot[key] {
                defaults.set(data, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    private func clearManagedPayloads() {
        PersonalRecordsPayloadMerger.managedPayloadKeys.forEach { defaults.removeObject(forKey: $0) }
    }

    private func quarantineUnownedSnapshotIfNeeded() {
        guard defaults.data(forKey: StorageKeys.unownedLegacySnapshot) == nil else { return }

        let snapshot = readSnapshot()
        guard !snapshot.isEmpty,
              let data = try? JSONEncoder().encode(snapshot)
        else {
            return
        }
        defaults.set(data, forKey: StorageKeys.unownedLegacySnapshot)
    }

    private func customBaseline(for uid: String) -> Snapshot {
        customBaselines()[uid] ?? [:]
    }

    private func establishCustomBaselineIfNeeded(from snapshot: Snapshot, for uid: String) {
        guard customBaselines()[uid] == nil else { return }
        persistCustomBaseline(from: snapshot, for: uid)
    }

    private func persistCustomBaseline(from snapshot: Snapshot, for uid: String) {
        var baselines = customBaselines()
        baselines[uid] = snapshot.filter {
            PersonalRecordsPayloadMerger.customPayloadKeys.contains($0.key)
        }

        guard let data = try? JSONEncoder().encode(baselines) else { return }
        defaults.set(data, forKey: StorageKeys.customBaselines)
    }

    private func customBaselines() -> [String: Snapshot] {
        guard let data = defaults.data(forKey: StorageKeys.customBaselines) else { return [:] }
        return (try? JSONDecoder().decode([String: Snapshot].self, from: data)) ?? [:]
    }

    private func hasPendingChanges(for uid: String) -> Bool {
        pendingSnapshots()[uid] != nil || pendingTombstones()[uid] != nil
    }

    private func pendingSnapshots() -> [String: Snapshot] {
        guard let data = defaults.data(forKey: StorageKeys.pendingSnapshots) else { return [:] }
        return (try? JSONDecoder().decode([String: Snapshot].self, from: data)) ?? [:]
    }

    private func persistPendingSnapshot(_ snapshot: Snapshot, for uid: String) {
        guard !uid.isEmpty else { return }

        var snapshots = pendingSnapshots()
        if snapshot.isEmpty, !(snapshots[uid] ?? [:]).isEmpty {
            return
        }
        snapshots[uid] = snapshot

        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        defaults.set(data, forKey: StorageKeys.pendingSnapshots)
    }

    private func pendingTombstones() -> [String: Tombstones] {
        guard let data = defaults.data(forKey: StorageKeys.pendingTombstones),
              let decoded = try? JSONDecoder().decode([String: [String: [String]]].self, from: data)
        else {
            return [:]
        }

        return decoded.mapValues { $0.mapValues(Set.init) }
    }

    private func persistPendingTombstones(_ tombstones: Tombstones, for uid: String) {
        guard !uid.isEmpty, !tombstones.isEmpty else { return }

        var allTombstones = pendingTombstones()
        allTombstones[uid] = PersonalRecordsPayloadMerger.mergeTombstones(
            allTombstones[uid] ?? [:],
            tombstones
        )

        let serializable = allTombstones.mapValues(PersonalRecordsPayloadMerger.tombstonesForFirestore)
        guard let data = try? JSONEncoder().encode(serializable) else { return }
        defaults.set(data, forKey: StorageKeys.pendingTombstones)
    }

    private func clearPendingChanges(for uid: String) {
        var snapshots = pendingSnapshots()
        snapshots.removeValue(forKey: uid)
        if snapshots.isEmpty {
            defaults.removeObject(forKey: StorageKeys.pendingSnapshots)
        } else if let data = try? JSONEncoder().encode(snapshots) {
            defaults.set(data, forKey: StorageKeys.pendingSnapshots)
        }

        var allTombstones = pendingTombstones()
        allTombstones.removeValue(forKey: uid)
        if allTombstones.isEmpty {
            defaults.removeObject(forKey: StorageKeys.pendingTombstones)
        } else if let data = try? JSONEncoder().encode(
            allTombstones.mapValues(PersonalRecordsPayloadMerger.tombstonesForFirestore)
        ) {
            defaults.set(data, forKey: StorageKeys.pendingTombstones)
        }
    }
}
