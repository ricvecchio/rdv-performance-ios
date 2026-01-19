import Foundation
import FirebaseFirestore

final class WorkoutTemplateRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()
    
    private enum Collections {
        static let workoutTemplates = "workout_templates"
    }
    
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
        
        // ✅ CORREÇÃO: EXATAMENTE COMO NO ORIGINAL - SEM orderBy
        let snap = try await db.collection(Collections.workoutTemplates)
            .whereField("teacherId", isEqualTo: t)
            .whereField("categoryRaw", isEqualTo: c)
            .whereField("sectionKey", isEqualTo: s)
            .limit(to: limit)
            .getDocuments()
        
        let list = try snap.documents.compactMap { try $0.data(as: WorkoutTemplateFS.self) }
        
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
