import Foundation
import FirebaseFirestore

struct StudentPersonalRecordsCloudDocument: Sendable {
    let payloads: [String: Data]
    let customTombstones: [String: [String]]
    let requiresMigration: Bool

    init(
        payloads: [String: Data],
        customTombstones: [String: [String]],
        requiresMigration: Bool = false
    ) {
        self.payloads = payloads
        self.customTombstones = customTombstones
        self.requiresMigration = requiresMigration
    }
}

final class StudentPersonalRecordsRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()

    private enum Collections {
        static let users = "users"
        static let personalRecords = "student_personal_records"
    }

    private enum DocumentIDs {
        static let metadata = "_metadata_v2"
        static let legacyV1 = "v1"

        static func payloadChunk(
            key: String,
            generation: String,
            index: Int
        ) -> String {
            "chunk_v3_\(key)_\(generation)_\(index)"
        }
    }

    private enum Fields {
        static let ownerID = "ownerId"
        static let schemaVersion = "schemaVersion"
        static let documentType = "documentType"
        static let payloadKey = "payloadKey"
        static let payload = "payload"
        static let payloadFormat = "payloadFormat"
        static let payloadGeneration = "payloadGeneration"
        static let chunkCount = "chunkCount"
        static let chunkIndex = "chunkIndex"
        static let customTombstones = "customTombstones"
        static let legacyV1Migrated = "legacyV1Migrated"
        static let syncRevision = "syncRevision"
        static let updatedAt = "updatedAt"
    }

    private enum DocumentTypes {
        static let metadata = "metadata"
        static let payload = "payload"
        static let payloadChunk = "payloadChunk"
    }

    private enum PayloadFormats {
        static let chunked = "chunked"
    }

    private enum SchemaVersions {
        static let legacy = 1
        static let partitioned = 2
        static let current = 3
    }

    private enum Limits {
        // Keeps each document well under Firestore's 1 MiB limit after field overhead.
        static let payloadChunkByteCount = 512 * 1024
        static let chunksPerBatch = 16
        static let documentIDsPerQuery = 30
        static let maximumChunkCount = 10_000
        static let saveAttempts = 3
    }

    private enum StorageKeys {
        static let pendingChunkCleanup = "student_pr_firestore_pending_chunk_cleanup_v1"
    }

    private struct PayloadStorage {
        let generation: String?
        let chunkCount: Int?
    }

    private struct ChunkWrite {
        let key: String
        let generation: String
        let revision: String
        let chunks: [Data]

        var storage: PayloadStorage {
            PayloadStorage(generation: generation, chunkCount: chunks.count)
        }
    }

    private struct CloudState {
        let document: StudentPersonalRecordsCloudDocument?
        let metadataVersion: DocumentVersion
        let legacyVersion: DocumentVersion
        let payloadVersions: [String: DocumentVersion]
        let payloadStorage: [String: PayloadStorage]
        let legacyWasMigrated: Bool
    }

    private struct DocumentVersion {
        let exists: Bool
        let revision: String?
        let legacyData: [String: Any]?
    }

    private struct PendingChunkCleanup: Codable, Hashable {
        let key: String
        let generation: String
        let chunkCount: Int
    }

    private static let concurrentChangeErrorDomain = "StudentPersonalRecordsRepository.concurrentChange"
    private let defaults = UserDefaults.standard

    func getStudentPersonalRecords(uid: String) async throws -> StudentPersonalRecordsCloudDocument? {
        let cleanUid = clean(uid)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }

        try await retryPendingChunkCleanup(uid: cleanUid)
        return try await loadCloudState(uid: cleanUid).document
    }

    func saveStudentPersonalRecords(
        uid: String,
        payloads: [String: Data],
        customTombstones: [String: [String]]
    ) async throws -> StudentPersonalRecordsCloudDocument {
        let cleanUid = clean(uid)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }

        let localPayloads = payloads.filter {
            PersonalRecordsPayloadMerger.managedPayloadKeys.contains($0.key)
        }
        let localTombstones = customTombstones.mapValues(Set.init)

        for _ in 0..<Limits.saveAttempts {
            try Task.checkCancellation()
            try await retryPendingChunkCleanup(uid: cleanUid)
            let state = try await loadCloudState(uid: cleanUid)
            try Task.checkCancellation()
            let remoteDocument = state.document
            let remoteTombstones = remoteDocument?.customTombstones ?? [:]
            let allTombstones = PersonalRecordsPayloadMerger.mergeTombstones(
                remoteTombstones,
                localTombstones
            )
            let mergedPayloads = PersonalRecordsPayloadMerger.mergeSnapshots(
                localPayloads,
                remoteDocument?.payloads ?? [:],
                tombstones: allTombstones
            )
            let chunkWrites = makeChunkWrites(
                for: mergedPayloads,
                remotePayloads: remoteDocument?.payloads ?? [:],
                remoteStorage: state.payloadStorage,
                migrateLegacyPayloads: remoteDocument?.requiresMigration == true
            )

            do {
                try await uploadChunks(chunkWrites, uid: cleanUid)
            } catch is CancellationError {
                enqueueChunkCleanup(chunkWrites, uid: cleanUid)
                throw CancellationError()
            } catch {
                enqueueChunkCleanup(chunkWrites, uid: cleanUid)
                try await retryPendingChunkCleanup(uid: cleanUid)
                throw error
            }

            guard !Task.isCancelled else {
                enqueueChunkCleanup(chunkWrites, uid: cleanUid)
                throw CancellationError()
            }
            enqueueReplacedChunkCleanup(
                chunkWrites,
                previousStorage: state.payloadStorage,
                uid: cleanUid
            )
            do {
                try await commitHeaders(
                    uid: cleanUid,
                    state: state,
                    chunkWrites: chunkWrites,
                    tombstones: allTombstones,
                    legacyWasMigrated: state.legacyWasMigrated,
                    metadataRevision: UUID().uuidString
                )
                try await retryPendingChunkCleanup(uid: cleanUid)

                return StudentPersonalRecordsCloudDocument(
                    payloads: mergedPayloads,
                    customTombstones: PersonalRecordsPayloadMerger.tombstonesForFirestore(allTombstones)
                )
            } catch where isConcurrentChange(error) {
                enqueueChunkCleanup(chunkWrites, uid: cleanUid)
                try await retryPendingChunkCleanup(uid: cleanUid)
                continue
            } catch {
                // An ambiguous commit result may still point a header at these chunks.
                // Cleanup only generations known not to have reached the header commit.
                throw error
            }
        }

        throw FirestoreRepositoryError.writeFailed
    }

    private func loadCloudState(uid: String) async throws -> CloudState {
        try Task.checkCancellation()
        let headerSnapshots = try await loadHeaderSnapshots(uid: uid)
        try Task.checkCancellation()
        let payloadSnapshots: [String: DocumentSnapshot] = Dictionary(
            uniqueKeysWithValues: PersonalRecordsPayloadMerger.managedPayloadKeys.compactMap { key in
                guard let snapshot = headerSnapshots[key] else { return nil }
                return (key, snapshot)
            }
        )
        let chunkSnapshots = try await loadActiveChunkSnapshots(
            from: payloadSnapshots,
            uid: uid
        )
        return cloudState(
            metadataSnapshot: headerSnapshots[DocumentIDs.metadata],
            legacySnapshot: headerSnapshots[DocumentIDs.legacyV1],
            payloadSnapshots: payloadSnapshots,
            chunkSnapshots: chunkSnapshots,
            uid: uid
        )
    }

    private func personalRecordsCollection(for uid: String) -> CollectionReference {
        db
            .collection(Collections.users)
            .document(uid)
            .collection(Collections.personalRecords)
    }

    private func loadHeaderSnapshots(uid: String) async throws -> [String: DocumentSnapshot] {
        let documentIDs = [DocumentIDs.metadata, DocumentIDs.legacyV1]
            + PersonalRecordsPayloadMerger.managedPayloadKeys
        var snapshots = [String: DocumentSnapshot]()

        for chunk in documentIDs.chunked(into: Limits.documentIDsPerQuery) {
            try Task.checkCancellation()
            let result = try await personalRecordsCollection(for: uid)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for snapshot in result.documents {
                snapshots[snapshot.documentID] = snapshot
            }
        }

        return snapshots
    }

    private func loadActiveChunkSnapshots(
        from payloadSnapshots: [String: DocumentSnapshot],
        uid: String
    ) async throws -> [DocumentSnapshot] {
        let documentIDs = payloadStorage(from: payloadSnapshots, uid: uid).flatMap { item in
            guard let generation = item.value.generation,
                  let chunkCount = item.value.chunkCount
            else {
                return [String]()
            }

            return (0..<chunkCount).map {
                DocumentIDs.payloadChunk(
                    key: item.key,
                    generation: generation,
                    index: $0
                )
            }
        }
        guard !documentIDs.isEmpty else { return [] }

        var snapshots = [DocumentSnapshot]()
        for chunk in documentIDs.chunked(into: Limits.documentIDsPerQuery) {
            try Task.checkCancellation()
            let result = try await personalRecordsCollection(for: uid)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            snapshots.append(contentsOf: result.documents)
        }

        return snapshots
    }

    private func cloudState(
        metadataSnapshot: DocumentSnapshot?,
        legacySnapshot: DocumentSnapshot?,
        payloadSnapshots: [String: DocumentSnapshot],
        chunkSnapshots: [DocumentSnapshot],
        uid: String
    ) -> CloudState {
        let decodedMetadata = metadataSnapshot.flatMap { snapshot in
            metadata(from: snapshot, uid: uid)
        }
        let legacy = legacySnapshot.flatMap { snapshot in
            legacyDocument(from: snapshot, uid: uid)
        }
        let chunkData = chunks(from: chunkSnapshots, uid: uid)
        let partitionedPayloads = payloads(
            from: payloadSnapshots,
            chunks: chunkData,
            uid: uid
        )
        let payloadStorage = payloadStorage(from: payloadSnapshots, uid: uid)
        var mergedSourcePayloads = partitionedPayloads

        if let legacy {
            for (key, data) in legacy.payloads {
                if let current = mergedSourcePayloads[key] {
                    mergedSourcePayloads[key] = PersonalRecordsPayloadMerger.mergePayload(
                        key: key,
                        local: data,
                        remote: current
                    )
                } else {
                    mergedSourcePayloads[key] = data
                }
            }
        }

        let partitionedTombstones = decodedMetadata?.customTombstones ?? [:]
        let tombstones = PersonalRecordsPayloadMerger.mergeTombstones(
            legacy?.customTombstones ?? [:],
            partitionedTombstones.mapValues { Set($0) }
        )
        let mergedPayloads = PersonalRecordsPayloadMerger.mergeSnapshots(
            [:],
            mergedSourcePayloads,
            tombstones: tombstones
        )
        let partitionedMergedPayloads = PersonalRecordsPayloadMerger.mergeSnapshots(
            [:],
            partitionedPayloads,
            tombstones: partitionedTombstones.mapValues { Set($0) }
        )
        let hasValidData = decodedMetadata != nil || legacy != nil || !mergedPayloads.isEmpty
        let document = hasValidData
            ? StudentPersonalRecordsCloudDocument(
                payloads: mergedPayloads,
                customTombstones: PersonalRecordsPayloadMerger.tombstonesForFirestore(tombstones),
                requiresMigration: legacy != nil && (
                    decodedMetadata?.legacyV1Migrated != true
                        || mergedPayloads != partitionedMergedPayloads
                        || tombstones != partitionedTombstones.mapValues { Set($0) }
                )
            )
            : nil

        return CloudState(
            document: document,
            metadataVersion: documentVersion(for: metadataSnapshot),
            legacyVersion: documentVersion(for: legacySnapshot),
            payloadVersions: Dictionary(
                uniqueKeysWithValues: PersonalRecordsPayloadMerger.managedPayloadKeys.map {
                    ($0, documentVersion(for: payloadSnapshots[$0]))
                }
            ),
            payloadStorage: payloadStorage,
            legacyWasMigrated: decodedMetadata?.legacyV1Migrated == true || legacy != nil
        )
    }

    private func metadata(
        from snapshot: DocumentSnapshot,
        uid: String
    ) -> (customTombstones: [String: [String]], legacyV1Migrated: Bool)? {
        guard snapshot.exists,
              let data = snapshot.data(),
              isOwned(data, by: uid, schemaVersions: [SchemaVersions.partitioned, SchemaVersions.current]),
              data[Fields.documentType] as? String == DocumentTypes.metadata
        else {
            return nil
        }

        return (
            customTombstones: tombstones(from: data),
            legacyV1Migrated: data[Fields.legacyV1Migrated] as? Bool ?? false
        )
    }

    private func legacyDocument(
        from snapshot: DocumentSnapshot,
        uid: String
    ) -> (payloads: [String: Data], customTombstones: [String: [String]])? {
        guard snapshot.exists,
              let data = snapshot.data(),
              isOwned(data, by: uid, schemaVersions: [SchemaVersions.legacy])
        else {
            return nil
        }

        let blobs = data["payloads"] as? [String: Any] ?? [:]
        let payloads = blobs.reduce(into: [String: Data]()) { result, item in
            guard PersonalRecordsPayloadMerger.managedPayloadKeys.contains(item.key),
                  let payload = item.value as? Data
            else {
                return
            }
            result[item.key] = payload
        }

        return (payloads: payloads, customTombstones: tombstones(from: data))
    }

    private func payloads(
        from snapshots: [String: DocumentSnapshot],
        chunks: [String: [String: [Int: Data]]],
        uid: String
    ) -> [String: Data] {
        snapshots.reduce(into: [String: Data]()) { result, item in
            guard let data = item.value.data(),
                  isOwned(
                    data,
                    by: uid,
                    schemaVersions: [SchemaVersions.partitioned, SchemaVersions.current]
                  ),
                  data[Fields.documentType] as? String == DocumentTypes.payload,
                  data[Fields.payloadKey] as? String == item.key
            else {
                return
            }

            if let payload = data[Fields.payload] as? Data {
                result[item.key] = payload
                return
            }

            guard let storage = chunkedPayloadStorage(from: data) else {
                return
            }
            guard let generation = storage.generation,
                  let chunkCount = storage.chunkCount
            else {
                return
            }
            if chunkCount == 0 {
                result[item.key] = Data()
                return
            }

            guard let payloadChunks = chunks[item.key]?[generation],
                  payloadChunks.count == chunkCount,
                  Set(payloadChunks.keys) == Set(0..<chunkCount)
            else {
                return
            }

            result[item.key] = (0..<chunkCount).reduce(into: Data()) {
                $0.append(payloadChunks[$1] ?? Data())
            }
        }
    }

    private func payloadStorage(
        from snapshots: [String: DocumentSnapshot],
        uid: String
    ) -> [String: PayloadStorage] {
        snapshots.reduce(into: [String: PayloadStorage]()) { result, item in
            guard let data = item.value.data(),
                  isOwned(
                    data,
                    by: uid,
                    schemaVersions: [SchemaVersions.partitioned, SchemaVersions.current]
                  ),
                  data[Fields.documentType] as? String == DocumentTypes.payload,
                  data[Fields.payloadKey] as? String == item.key
            else {
                return
            }

            result[item.key] = chunkedPayloadStorage(from: data)
                ?? PayloadStorage(generation: nil, chunkCount: nil)
        }
    }

    private func chunkedPayloadStorage(from data: [String: Any]) -> PayloadStorage? {
        guard data[Fields.payloadFormat] as? String == PayloadFormats.chunked,
              let generation = data[Fields.payloadGeneration] as? String,
              !generation.isEmpty,
              let count = exactNonnegativeInt(data[Fields.chunkCount]),
              count <= Limits.maximumChunkCount
        else {
            return nil
        }

        return PayloadStorage(generation: generation, chunkCount: count)
    }

    private func chunks(
        from snapshots: [DocumentSnapshot],
        uid: String
    ) -> [String: [String: [Int: Data]]] {
        snapshots.reduce(into: [String: [String: [Int: Data]]]()) { result, snapshot in
            guard let data = snapshot.data(),
                  isOwned(data, by: uid, schemaVersions: [SchemaVersions.current]),
                  data[Fields.documentType] as? String == DocumentTypes.payloadChunk,
                  let key = data[Fields.payloadKey] as? String,
                  PersonalRecordsPayloadMerger.managedPayloadKeys.contains(key),
                  let generation = data[Fields.payloadGeneration] as? String,
                  !generation.isEmpty,
                  let index = exactNonnegativeInt(data[Fields.chunkIndex]),
                  let payload = data[Fields.payload] as? Data,
                  snapshot.documentID == DocumentIDs.payloadChunk(
                    key: key,
                    generation: generation,
                    index: index
                  )
            else {
                return
            }

            result[key, default: [:]][generation, default: [:]][index] = payload
        }
    }

    private func makeChunkWrites(
        for mergedPayloads: [String: Data],
        remotePayloads: [String: Data],
        remoteStorage: [String: PayloadStorage],
        migrateLegacyPayloads: Bool
    ) -> [ChunkWrite] {
        PersonalRecordsPayloadMerger.managedPayloadKeys.compactMap { key in
            guard let payload = mergedPayloads[key] else { return nil }

            let mustMigrateLegacyPayload = migrateLegacyPayloads && remoteStorage[key] == nil
            guard payload != remotePayloads[key] || mustMigrateLegacyPayload else {
                return nil
            }

            return ChunkWrite(
                key: key,
                generation: UUID().uuidString,
                revision: UUID().uuidString,
                chunks: split(payload)
            )
        }
    }

    private func split(_ payload: Data) -> [Data] {
        guard !payload.isEmpty else { return [] }

        return stride(from: 0, to: payload.count, by: Limits.payloadChunkByteCount).map {
            payload.subdata(in: $0..<min($0 + Limits.payloadChunkByteCount, payload.count))
        }
    }

    private func uploadChunks(_ writes: [ChunkWrite], uid: String) async throws {
        let references = writes.flatMap { write in
            write.chunks.enumerated().map { index, payload in
                (
                    reference: personalRecordsCollection(for: uid).document(
                        DocumentIDs.payloadChunk(
                            key: write.key,
                            generation: write.generation,
                            index: index
                        )
                    ),
                    data: payloadChunkDocumentData(
                        uid: uid,
                        key: write.key,
                        generation: write.generation,
                        index: index,
                        payload: payload
                    )
                )
            }
        }

        for start in stride(from: 0, to: references.count, by: Limits.chunksPerBatch) {
            try Task.checkCancellation()
            let batch = db.batch()
            for item in references[start..<min(start + Limits.chunksPerBatch, references.count)] {
                batch.setData(item.data, forDocument: item.reference)
            }
            try await batch.commit()
        }
    }

    private func commitHeaders(
        uid: String,
        state: CloudState,
        chunkWrites: [ChunkWrite],
        tombstones: PersonalRecordsPayloadMerger.Tombstones,
        legacyWasMigrated: Bool,
        metadataRevision: String
    ) async throws {
        let records = personalRecordsCollection(for: uid)
        let metadataReference = records.document(DocumentIDs.metadata)
        let legacyReference = records.document(DocumentIDs.legacyV1)
        let payloadReferences = Dictionary(
            uniqueKeysWithValues: chunkWrites.map {
                ($0.key, records.document($0.key))
            }
        )

        try Task.checkCancellation()
        let result = try await db.runTransaction { transaction, errorPointer in
            do {
                let metadataSnapshot = try transaction.getDocument(metadataReference)
                let legacySnapshot = try transaction.getDocument(legacyReference)
                guard self.matches(metadataSnapshot, expected: state.metadataVersion),
                      self.matches(legacySnapshot, expected: state.legacyVersion)
                else {
                    throw self.concurrentChangeError()
                }

                for (key, reference) in payloadReferences {
                    let snapshot = try transaction.getDocument(reference)
                    guard let expected = state.payloadVersions[key],
                          self.matches(snapshot, expected: expected)
                    else {
                        throw self.concurrentChangeError()
                    }
                }

                for write in chunkWrites {
                    guard let reference = payloadReferences[write.key] else { continue }
                    transaction.setData(
                        self.payloadDocumentData(
                            uid: uid,
                            key: write.key,
                            storage: write.storage,
                            revision: write.revision
                        ),
                        forDocument: reference
                    )
                }

                transaction.setData(
                    self.metadataDocumentData(
                        uid: uid,
                        tombstones: tombstones,
                        legacyWasMigrated: legacyWasMigrated,
                        revision: metadataRevision
                    ),
                    forDocument: metadataReference
                )
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        guard result as? Bool == true else {
            throw FirestoreRepositoryError.writeFailed
        }
    }

    private func enqueueReplacedChunkCleanup(
        _ writes: [ChunkWrite],
        previousStorage: [String: PayloadStorage],
        uid: String
    ) {
        enqueueChunkCleanup(
            writes.compactMap { write in
                guard let storage = previousStorage[write.key],
                      let generation = storage.generation,
                      let chunkCount = storage.chunkCount
                else {
                    return nil
                }
                return PendingChunkCleanup(
                    key: write.key,
                    generation: generation,
                    chunkCount: chunkCount
                )
            },
            uid: uid
        )
    }

    private func enqueueChunkCleanup(_ writes: [ChunkWrite], uid: String) {
        enqueueChunkCleanup(
            writes.map {
                PendingChunkCleanup(
                    key: $0.key,
                    generation: $0.generation,
                    chunkCount: $0.chunks.count
                )
            },
            uid: uid
        )
    }

    private func enqueueChunkCleanup(_ cleanup: [PendingChunkCleanup], uid: String) {
        let validCleanup = cleanup.filter(isValid)
        guard !validCleanup.isEmpty else { return }

        var pending = pendingChunkCleanup()
        pending[uid] = Array(
            Set(pending[uid, default: []]).union(validCleanup)
        ).sorted(by: cleanupComesBefore)
        persistPendingChunkCleanup(pending)
    }

    private func retryPendingChunkCleanup(uid: String) async throws {
        let cleanup = pendingChunkCleanup()[uid] ?? []
        guard !cleanup.isEmpty else { return }

        var remaining = [PendingChunkCleanup]()
        for item in cleanup {
            try Task.checkCancellation()
            do {
                if try await deleteChunksIfInactive(item, uid: uid) {
                    continue
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Keep the generation journaled and retry on the next read or save.
            }
            remaining.append(item)
        }

        var pending = pendingChunkCleanup()
        if remaining.isEmpty {
            pending.removeValue(forKey: uid)
        } else {
            pending[uid] = remaining
        }
        persistPendingChunkCleanup(pending)
    }

    private func deleteChunksIfInactive(
        _ cleanup: PendingChunkCleanup,
        uid: String
    ) async throws -> Bool {
        let records = personalRecordsCollection(for: uid)
        let headerReference = records.document(cleanup.key)

        for start in stride(from: 0, to: cleanup.chunkCount, by: Limits.chunksPerBatch) {
            try Task.checkCancellation()
            let end = min(start + Limits.chunksPerBatch, cleanup.chunkCount)
            let didDelete = try await db.runTransaction { transaction, errorPointer in
                do {
                    let header = try transaction.getDocument(headerReference)
                    guard !self.references(cleanup, from: header, uid: uid) else {
                        return false
                    }

                    for index in start..<end {
                        transaction.deleteDocument(
                            records.document(
                                DocumentIDs.payloadChunk(
                                    key: cleanup.key,
                                    generation: cleanup.generation,
                                    index: index
                                )
                            )
                        )
                    }
                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            guard let didDelete = didDelete as? Bool else {
                throw FirestoreRepositoryError.writeFailed
            }
            guard didDelete else { return false }
        }

        return true
    }

    private func references(
        _ cleanup: PendingChunkCleanup,
        from snapshot: DocumentSnapshot,
        uid: String
    ) -> Bool {
        guard let data = snapshot.data(),
              isOwned(
                data,
                by: uid,
                schemaVersions: [SchemaVersions.partitioned, SchemaVersions.current]
              ),
              data[Fields.documentType] as? String == DocumentTypes.payload,
              data[Fields.payloadKey] as? String == cleanup.key,
              let storage = chunkedPayloadStorage(from: data)
        else {
            return false
        }

        return storage.generation == cleanup.generation
    }

    private func pendingChunkCleanup() -> [String: [PendingChunkCleanup]] {
        guard let data = defaults.data(forKey: StorageKeys.pendingChunkCleanup),
              let pending = try? JSONDecoder().decode(
                [String: [PendingChunkCleanup]].self,
                from: data
              )
        else {
            return [:]
        }

        return pending.mapValues { $0.filter(isValid) }
    }

    private func persistPendingChunkCleanup(_ pending: [String: [PendingChunkCleanup]]) {
        guard !pending.isEmpty else {
            defaults.removeObject(forKey: StorageKeys.pendingChunkCleanup)
            return
        }
        guard let data = try? JSONEncoder().encode(pending) else { return }
        defaults.set(data, forKey: StorageKeys.pendingChunkCleanup)
    }

    private func isValid(_ cleanup: PendingChunkCleanup) -> Bool {
        PersonalRecordsPayloadMerger.managedPayloadKeys.contains(cleanup.key)
            && !cleanup.generation.isEmpty
            && (0...Limits.maximumChunkCount).contains(cleanup.chunkCount)
    }

    private func cleanupComesBefore(
        _ first: PendingChunkCleanup,
        _ second: PendingChunkCleanup
    ) -> Bool {
        if first.key != second.key {
            return first.key < second.key
        }
        return first.generation < second.generation
    }

    private func isOwned(
        _ data: [String: Any],
        by uid: String,
        schemaVersions: [Int]
    ) -> Bool {
        guard data[Fields.ownerID] as? String == uid,
              let version = data[Fields.schemaVersion] as? NSNumber
        else {
            return false
        }
        return schemaVersions.contains(version.intValue)
    }

    private func tombstones(from data: [String: Any]) -> [String: [String]] {
        guard let rawTombstones = data[Fields.customTombstones] as? [String: Any] else {
            return [:]
        }

        return rawTombstones.reduce(into: [String: [String]]()) { result, item in
            guard PersonalRecordsPayloadMerger.managedPayloadKeys.contains(item.key),
                  let values = item.value as? [String]
            else {
                return
            }
            result[item.key] = Array(Set(values)).sorted()
        }
    }

    private func payloadDocumentData(
        uid: String,
        key: String,
        storage: PayloadStorage,
        revision: String
    ) -> [String: Any] {
        [
            Fields.ownerID: uid,
            Fields.schemaVersion: SchemaVersions.current,
            Fields.documentType: DocumentTypes.payload,
            Fields.payloadKey: key,
            Fields.payloadFormat: PayloadFormats.chunked,
            Fields.payloadGeneration: storage.generation ?? "",
            Fields.chunkCount: storage.chunkCount ?? 0,
            Fields.syncRevision: revision,
            Fields.updatedAt: FieldValue.serverTimestamp()
        ]
    }

    private func payloadChunkDocumentData(
        uid: String,
        key: String,
        generation: String,
        index: Int,
        payload: Data
    ) -> [String: Any] {
        [
            Fields.ownerID: uid,
            Fields.schemaVersion: SchemaVersions.current,
            Fields.documentType: DocumentTypes.payloadChunk,
            Fields.payloadKey: key,
            Fields.payloadGeneration: generation,
            Fields.chunkIndex: index,
            Fields.payload: payload,
            Fields.syncRevision: UUID().uuidString,
            Fields.updatedAt: FieldValue.serverTimestamp()
        ]
    }

    private func metadataDocumentData(
        uid: String,
        tombstones: PersonalRecordsPayloadMerger.Tombstones,
        legacyWasMigrated: Bool,
        revision: String
    ) -> [String: Any] {
        [
            Fields.ownerID: uid,
            Fields.schemaVersion: SchemaVersions.current,
            Fields.documentType: DocumentTypes.metadata,
            Fields.customTombstones: PersonalRecordsPayloadMerger.tombstonesForFirestore(tombstones),
            Fields.legacyV1Migrated: legacyWasMigrated,
            Fields.syncRevision: revision,
            Fields.updatedAt: FieldValue.serverTimestamp()
        ]
    }

    private func documentVersion(for snapshot: DocumentSnapshot?) -> DocumentVersion {
        guard let snapshot, snapshot.exists, let data = snapshot.data() else {
            return DocumentVersion(exists: false, revision: nil, legacyData: nil)
        }

        return DocumentVersion(
            exists: true,
            revision: data[Fields.syncRevision] as? String,
            legacyData: data[Fields.syncRevision] as? String == nil ? data : nil
        )
    }

    private func matches(_ snapshot: DocumentSnapshot, expected: DocumentVersion) -> Bool {
        guard snapshot.exists == expected.exists else { return false }
        guard expected.exists else { return true }
        guard let data = snapshot.data() else { return false }

        if let revision = expected.revision {
            return data[Fields.syncRevision] as? String == revision
        }
        return NSDictionary(dictionary: data).isEqual(to: expected.legacyData ?? [:])
    }

    private func exactNonnegativeInt(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber else { return nil }
        let double = number.doubleValue
        guard double.isFinite,
              double.rounded(.towardZero) == double,
              double >= 0,
              double <= Double(Int.max)
        else {
            return nil
        }
        return number.intValue
    }

    private func concurrentChangeError() -> NSError {
        NSError(
            domain: Self.concurrentChangeErrorDomain,
            code: 1
        )
    }

    private func isConcurrentChange(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == Self.concurrentChangeErrorDomain && error.code == 1
    }
}
