import Foundation
import FirebaseFirestore
import os.log

final class WorkoutTemplateRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()

    private enum Collections {
        static let workoutTemplates = "workout_templates"
    }

    private static let debugLog = OSLog(subsystem: "com.rdvperformance.app", category: "WorkoutTemplateRepository")

    func createWorkoutTemplate(
        teacherId: String,
        categoryRaw: String,
        sectionKey: String,
        title: String,
        description: String,
        blocks: [BlockFS] = []
    ) async throws -> String {
        
        let t = clean(teacherId)
        let c = clean(categoryRaw)
        let s = clean(sectionKey)
        let titleTrim = clean(title)
        let descTrim = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        guard !s.isEmpty else { throw FirestoreRepositoryError.invalidData }
        guard !titleTrim.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        var payload: [String: Any] = [
            "teacherId": t,
            "categoryRaw": c,
            "sectionKey": s,
            "title": titleTrim,
            "description": descTrim,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if !blocks.isEmpty {
            payload["blocks"] = blocks.map { ["id": $0.id, "name": $0.name, "details": $0.details] }
        }
        
        let ref = db.collection(Collections.workoutTemplates).document()
        try await ref.setData(payload, merge: true)
        return ref.documentID
    }

    /// Cria vários templates em uma única viagem de rede (Firestore WriteBatch), em vez de
    /// N `createWorkoutTemplate` sequenciais awaited um a um. Usado pelo seed de defaults,
    /// que antes podia disparar dezenas de writes sequenciais e travar a tela em "carregando".
    func createWorkoutTemplatesBatch(
        teacherId: String,
        categoryRaw: String,
        sectionKey: String,
        items: [(title: String, description: String, blocks: [BlockFS])]
    ) async throws {
        guard !items.isEmpty else { return }

        let t = clean(teacherId)
        let c = clean(categoryRaw)
        let s = clean(sectionKey)

        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        guard !s.isEmpty else { throw FirestoreRepositoryError.invalidData }

        // Firestore limita 500 operações por batch; na prática os seeds de uma seção
        // nunca chegam perto disso, mas particionamos por segurança.
        for chunk in items.chunked(into: 450) {
            let batch = db.batch()

            for item in chunk {
                let titleTrim = clean(item.title)
                guard !titleTrim.isEmpty else { continue }

                var payload: [String: Any] = [
                    "teacherId": t,
                    "categoryRaw": c,
                    "sectionKey": s,
                    "title": titleTrim,
                    "description": item.description.trimmingCharacters(in: .whitespacesAndNewlines),
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]

                if !item.blocks.isEmpty {
                    payload["blocks"] = item.blocks.map { ["id": $0.id, "name": $0.name, "details": $0.details] }
                }

                let ref = db.collection(Collections.workoutTemplates).document()
                batch.setData(payload, forDocument: ref, merge: true)
            }

            try await batch.commit()
        }
    }
    
    func getWorkoutTemplates(
        teacherId: String,
        categoryRaw: String,
        sectionKey: String,
        limit: Int = 100
    ) async throws -> [WorkoutTemplateFS] {
        
        let t = clean(teacherId)
        let c = clean(categoryRaw)
        let s = clean(sectionKey)
        
        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        guard !s.isEmpty else { throw FirestoreRepositoryError.invalidData }

        #if DEBUG
        let debugStart = Date()
        os_log("getWorkoutTemplates START teacherId=%{public}@ category=%{public}@ section=%{public}@", log: Self.debugLog, type: .debug, t, c, s)
        #endif

        // ✅ Sem orderBy no servidor: como há 3 filtros de igualdade (teacherId, categoryRaw,
        // sectionKey) e NENHUM orderBy, o Firestore não exige índice composto aqui (só seria
        // necessário se combinássemos igualdade + orderBy em campo diferente). A ordenação é
        // feita localmente, evitando dependência de índice que poderia falhar silenciosamente
        // em produção caso não fosse criado no console do Firebase.
        let snap = try await db.collection(Collections.workoutTemplates)
            .whereField("teacherId", isEqualTo: t)
            .whereField("categoryRaw", isEqualTo: c)
            .whereField("sectionKey", isEqualTo: s)
            .limit(to: limit)
            .getDocuments()
        
        let list = try snap.documents.compactMap { try $0.data(as: WorkoutTemplateFS.self) }

        #if DEBUG
        let elapsedMs = Date().timeIntervalSince(debugStart) * 1000
        os_log("getWorkoutTemplates END docs=%d durationMs=%.0f", log: Self.debugLog, type: .debug, list.count, elapsedMs)
        #endif
        
        // ✅ Ordenação LOCALMENTE, como no original
        return list.sorted {
            let a = $0.createdAt?.dateValue() ?? Date.distantPast
            let b = $1.createdAt?.dateValue() ?? Date.distantPast
            return a > b
        }
    }
    
    func updateWorkoutTemplateBlocks(
        templateId: String,
        blocks: [BlockFS]
    ) async throws {
        
        let id = clean(templateId)
        guard !id.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let payload: [String: Any] = [
            "blocks": blocks.map { ["id": $0.id, "name": $0.name, "details": $0.details] },
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection(Collections.workoutTemplates)
            .document(id)
            .setData(payload, merge: true)
    }
    
    func deleteWorkoutTemplate(templateId: String) async throws {
        let id = clean(templateId)
        guard !id.isEmpty else {
            throw FirestoreRepositoryError.deleteFailed("templateId inválido para remoção.")
        }
        
        try await db
            .collection(Collections.workoutTemplates)
            .document(id)
            .delete()
    }
}
