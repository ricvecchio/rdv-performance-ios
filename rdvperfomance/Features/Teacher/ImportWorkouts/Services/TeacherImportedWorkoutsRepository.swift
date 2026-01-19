import Foundation
import FirebaseAuth
import FirebaseFirestore

struct TeacherImportedWorkoutsRepository {
    
    static func getTeacherId() -> String? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return uid.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func saveImportedWorkoutsBatch(teacherId: String, items: [ImportedWorkoutPayload]) async throws {
        let db = Firestore.firestore()
        
        let col = db
            .collection("teachers")
            .document(teacherId)
            .collection("importedWorkouts")
        
        let chunks = items.chunked(into: 400)
        
        for chunk in chunks {
            let batch = db.batch()
            
            for item in chunk {
                let docRef = col.document()
                batch.setData([
                    "title": item.title,
                    "description": item.description,
                    "aquecimento": item.aquecimento,
                    "tecnica": item.tecnica,
                    "wod": item.wod,
                    "cargasMovimentos": item.cargasMovimentos,
                    "createdAt": Timestamp(date: Date()),
                    "source": "excel"
                ], forDocument: docRef)
            }
            
            try await batch.commit()
        }
    }
    
    static func loadWorkouts(teacherId: String) async throws -> [TeacherImportedWorkout] {
        let snap = try await Firestore.firestore()
            .collection("teachers")
            .document(teacherId)
            .collection("importedWorkouts")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let parsed: [TeacherImportedWorkout] = snap.documents.compactMap { doc in
            let data = doc.data()
            
            let title = (data["title"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let description = (data["description"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let aquecimento = (data["aquecimento"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let tecnica = (data["tecnica"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let wod = (data["wod"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let cargasMovimentos = (data["cargasMovimentos"] as? String ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            return TeacherImportedWorkout(
                id: doc.documentID,
                title: title,
                description: description,
                aquecimento: aquecimento,
                tecnica: tecnica,
                wod: wod,
                cargasMovimentos: cargasMovimentos
            )
        }
        
        return parsed
    }
    
    static func addWorkout(teacherId: String, title: String) async throws {
        let cleanedTitle = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Informe um título para o treino."])
        }
        
        let payload: [String: Any] = [
            "title": cleanedTitle,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await Firestore.firestore()
            .collection("teachers")
            .document(teacherId)
            .collection("importedWorkouts")
            .addDocument(data: payload)
    }
    
    static func deleteWorkout(teacherId: String, workoutId: String) async throws {
        try await Firestore.firestore()
            .collection("teachers")
            .document(teacherId)
            .collection("importedWorkouts")
            .document(workoutId)
            .delete()
    }
    
    static func updateWorkout(teacherId: String, workoutId: String, updates: [String: Any]) async throws {
        try await Firestore.firestore()
            .collection("teachers")
            .document(teacherId)
            .collection("importedWorkouts")
            .document(workoutId)
            .updateData(updates)
    }
}
