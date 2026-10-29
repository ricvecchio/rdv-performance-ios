import Foundation
import FirebaseFirestore
import UIKit

/// Acesso ao Firestore do recurso Atletas.
///
/// Estrutura (ver `firebase/ATHLETES.md`):
/// - `publicAthletes/{uid}`: projeção pública mínima (nome, foto reduzida, privacidade, prCount).
/// - `publicAthletes/{uid}/records/{categoryKey}`: cópia resumida dos PRs, existente somente com perfil público.
/// - `users/{uid}/favoriteAthletes/{athleteId}`: favoritos do usuário autenticado.
final class AthletesService: @unchecked Sendable {

    static let shared = AthletesService()

    enum ServiceError: Error {
        case missingUserId
        case profileUnavailable
    }

    private enum Collections {
        static let users = "users"
        static let athletes = "publicAthletes"
        static let records = "records"
        static let favorites = "favoriteAthletes"
    }

    private let db = Firestore.firestore()
    private let lock = NSLock()
    private var publishedSignatures = [String: String]()

    private init() {}

    // MARK: - Perfil público

    /// Cria/atualiza a projeção pública do usuário autenticado. Nunca altera `users/{uid}`.
    /// Perfis novos são criados como **privados** com 0 PRs; privacidade e prCount existentes são preservados.
    func ensurePublicProfile(
        uid: String,
        name: String?,
        photoBase64: String?,
        userType: String?,
        active: Bool?
    ) async {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty, !cleanName.isEmpty, active != false else { return }
        guard (userType ?? "").uppercased() != "ADMIN" else { return }

        let thumbnail = await Task.detached(priority: .utility) {
            Self.thumbnailBase64(from: photoBase64)
        }.value

        let reference = db.collection(Collections.athletes).document(cleanUid)

        do {
            let snapshot = try await reference.getDocument(source: .server)
            let existing = snapshot.data()

            var data: [String: Any] = [
                "ownerId": cleanUid,
                "name": cleanName,
                "nameLower": AthleteSearchText.normalize(cleanName),
                "searchPrefixes": AthleteSearchText.prefixes(for: cleanName),
                "photoThumbBase64": thumbnail ?? "",
                "updatedAt": FieldValue.serverTimestamp()
            ]

            if let existing {
                let unchanged = existing["name"] as? String == cleanName
                    && (existing["photoThumbBase64"] as? String ?? "") == (thumbnail ?? "")
                    && existing["searchPrefixes"] is [Any]
                    && existing["ownerId"] as? String == cleanUid
                    && existing["privacy"] is String
                    && existing["prCount"] is NSNumber
                if unchanged { return }

                // Preserva privacidade e contagem (prCount é mantido pelo backend);
                // completa campos ausentes de perfis antigos.
                data["privacy"] = AthletePrivacy(storedValue: existing["privacy"] as? String).rawValue
                if !(existing["prCount"] is NSNumber) {
                    data["prCount"] = 0
                }
                try await reference.setData(data, merge: true)
            } else {
                data["privacy"] = AthletePrivacy.private.rawValue
                data["prCount"] = 0
                try await reference.setData(data)
            }
        } catch {
            #if DEBUG
            print("[Athletes] ensurePublicProfile falhou: \(error)")
            #endif
        }
    }

    func athlete(id: String) async throws -> PublicAthlete? {
        let snapshot = try await db.collection(Collections.athletes).document(id).getDocument(source: .server)
        guard let data = snapshot.data() else { return nil }
        return Self.athlete(id: id, data: data)
    }

    func athletes(ids: [String]) async -> [PublicAthlete] {
        await withTaskGroup(of: PublicAthlete?.self) { group in
            for id in ids {
                group.addTask { [self] in try? await athlete(id: id) }
            }

            var result = [PublicAthlete]()
            for await item in group {
                if let item { result.append(item) }
            }
            return result
        }
    }

    // MARK: - Busca

    /// Busca por início de qualquer palavra do nome (sem diferenciar maiúsculas/acentos), limitada.
    func searchAthletes(
        query: String,
        excluding currentUid: String?,
        limit: Int = 30
    ) async throws -> [PublicAthlete] {
        let words = AthleteSearchText.words(query)
        guard let first = words.first else { return [] }

        let prefix = String(first.prefix(AthleteSearchText.maxPrefixLength))
        let snapshot = try await db.collection(Collections.athletes)
            .whereField("searchPrefixes", arrayContains: prefix)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { document -> PublicAthlete? in
                guard document.documentID != currentUid else { return nil }
                let data = document.data()
                let nameWords = AthleteSearchText.words(data["name"] as? String ?? "")
                guard words.allSatisfy({ word in nameWords.contains { $0.hasPrefix(word) } }) else { return nil }
                return Self.athlete(id: document.documentID, data: data)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Favoritos

    func favoriteIds(uid: String) async throws -> [String] {
        guard !uid.isEmpty else { throw ServiceError.missingUserId }

        let snapshot = try await db.collection(Collections.users)
            .document(uid)
            .collection(Collections.favorites)
            .getDocuments()

        return snapshot.documents
            .sorted {
                let first = ($0.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                let second = ($1.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                return first > second
            }
            .map(\.documentID)
    }

    /// O identificador do documento é o do atleta: impede duplicidades.
    func setFavorite(uid: String, athleteId: String, isFavorite: Bool) async throws {
        guard !uid.isEmpty, !athleteId.isEmpty else { throw ServiceError.missingUserId }

        let reference = db.collection(Collections.users)
            .document(uid)
            .collection(Collections.favorites)
            .document(athleteId)

        if isFavorite {
            try await reference.setData([
                "athleteId": athleteId,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await reference.delete()
        }
    }

    // MARK: - Privacidade

    /// Altera a privacidade e sincroniza a cópia pública dos recordes.
    /// A privacidade é gravada primeiro: a regra do Firestore bloqueia a leitura imediatamente ao tornar privado.
    func setPrivacy(uid: String, privacy: AthletePrivacy) async throws {
        guard !uid.isEmpty else { throw ServiceError.missingUserId }

        let reference = db.collection(Collections.athletes).document(uid)
        let snapshot = try await reference.getDocument(source: .server)
        guard snapshot.exists else { throw ServiceError.profileUnavailable }

        try await reference.updateData([
            "privacy": privacy.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        clearSignature(for: uid)

        switch privacy {
        case .private:
            await deleteAllRecords(uid: uid)
        case .public:
            if let document = try? await PersonalRecordsRepository().getPersonalRecords(uid: uid) {
                await publishRecords(uid: uid, payloads: document.payloads)
            }
        }
    }

    // MARK: - Recordes publicados

    /// Com perfil público, atualiza a cópia resumida dos recordes. O `prCount` é mantido exclusivamente
    /// pelo backend (Cloud Function `syncPublicAthletePrCount`). Falhas são silenciosas
    /// (não interferem na sincronização dos Personal Records).
    func publishRecords(uid: String, payloads: [String: Data]) async {
        guard !uid.isEmpty else { return }

        let categories = AthleteRecordsSummary.build(from: payloads)
        let reference = db.collection(Collections.athletes).document(uid)

        do {
            let snapshot = try await reference.getDocument(source: .server)
            guard let data = snapshot.data() else { return }

            let privacy = AthletePrivacy(storedValue: data["privacy"] as? String)
            let signature = Self.signature(privacy: privacy, categories: categories)
            guard signature != currentSignature(for: uid) else { return }

            switch privacy {
            case .private:
                await deleteAllRecords(uid: uid)
            case .public:
                try await replaceRecords(uid: uid, categories: categories)
            }

            storeSignature(signature, for: uid)
        } catch {
            #if DEBUG
            print("[Athletes] publishRecords falhou: \(error)")
            #endif
        }
    }

    private func replaceRecords(uid: String, categories: [AthleteRecordCategory]) async throws {
        let collection = db.collection(Collections.athletes).document(uid).collection(Collections.records)
        let existing = try await collection.getDocuments()
        let keep = Set(categories.map(\.key))

        let batch = db.batch()
        for category in categories {
            batch.setData(
                [
                    "ownerId": uid,
                    "categoryKey": category.key,
                    "items": AthleteRecordsSummary.documentItems(for: category),
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                forDocument: collection.document(category.key)
            )
        }
        for document in existing.documents where !keep.contains(document.documentID) {
            batch.deleteDocument(document.reference)
        }
        try await batch.commit()
    }

    private func deleteAllRecords(uid: String) async {
        let collection = db.collection(Collections.athletes).document(uid).collection(Collections.records)

        do {
            let existing = try await collection.getDocuments()
            guard !existing.documents.isEmpty else { return }

            let batch = db.batch()
            for document in existing.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        } catch {
            #if DEBUG
            print("[Athletes] deleteAllRecords falhou: \(error)")
            #endif
        }
    }

    /// Leitura dos recordes de outro atleta. Lança erro de permissão quando o perfil é privado.
    func records(athleteId: String) async throws -> [AthleteRecordCategory] {
        let snapshot = try await db.collection(Collections.athletes)
            .document(athleteId)
            .collection(Collections.records)
            .getDocuments()

        let order = ["barbell", "gymnastic", "endurance", "notables", "girls", "open", "heroes", "campeonatos", "crossfit_games"]

        return snapshot.documents
            .compactMap { document -> AthleteRecordCategory? in
                let items = AthleteRecordsSummary.items(fromDocument: document.data(), categoryKey: document.documentID)
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                return items.isEmpty ? nil : AthleteRecordCategory(key: document.documentID, items: items)
            }
            .sorted {
                (order.firstIndex(of: $0.key) ?? order.count) < (order.firstIndex(of: $1.key) ?? order.count)
            }
    }

    // MARK: - Auxiliares

    private static func athlete(id: String, data: [String: Any]) -> PublicAthlete? {
        guard let name = data["name"] as? String, !name.isEmpty else { return nil }

        let thumb = (data["photoThumbBase64"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return PublicAthlete(
            id: id,
            name: name,
            photoThumbBase64: thumb.isEmpty ? nil : thumb,
            privacy: AthletePrivacy(storedValue: data["privacy"] as? String),
            prCount: max(0, (data["prCount"] as? NSNumber)?.intValue ?? 0)
        )
    }

    private static func signature(privacy: AthletePrivacy, categories: [AthleteRecordCategory]) -> String {
        let body = categories
            .flatMap(\.items)
            .map { "\($0.id)|\($0.name)|\($0.value)|\($0.unit)" }
            .joined(separator: ";")
        return "\(privacy.rawValue)#\(body)"
    }

    private func currentSignature(for uid: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return publishedSignatures[uid]
    }

    private func storeSignature(_ signature: String, for uid: String) {
        lock.lock()
        publishedSignatures[uid] = signature
        lock.unlock()
    }

    private func clearSignature(for uid: String) {
        lock.lock()
        publishedSignatures[uid] = nil
        lock.unlock()
    }

    /// Foto reduzida (96 px) para listas; a foto original em `users` não é exposta.
    private static func thumbnailBase64(from base64: String?) -> String? {
        var raw = (base64 ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        if let commaIndex = raw.firstIndex(of: ","), raw.lowercased().contains("base64") {
            raw = String(raw[raw.index(after: commaIndex)...])
        }

        guard let data = Data(base64Encoded: raw, options: [.ignoreUnknownCharacters]),
              let image = UIImage(data: data),
              image.size.width > 0, image.size.height > 0
        else {
            return nil
        }

        let side: CGFloat = 96
        let scale = max(side / image.size.width, side / image.size.height)
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(
                x: (side - target.width) / 2,
                y: (side - target.height) / 2,
                width: target.width,
                height: target.height
            ))
        }

        return resized.jpegData(compressionQuality: 0.7)?.base64EncodedString()
    }
}


