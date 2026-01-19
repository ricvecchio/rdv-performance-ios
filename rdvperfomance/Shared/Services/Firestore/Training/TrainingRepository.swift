import Foundation
import FirebaseFirestore

final class TrainingRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()
    
    func getWeeksForStudent(studentId: String, onlyPublished: Bool = true) async throws -> [TrainingWeekFS] {
        let cleanStudentId = clean(studentId)
        guard !cleanStudentId.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        
        var query: Query = db.collection(TrainingFS.weeksCollection)
            .whereField("studentId", isEqualTo: cleanStudentId)
        
        if onlyPublished {
            query = query.whereField("isPublished", isEqualTo: true)
        }
        
        let snap: QuerySnapshot
        do {
            snap = try await query.order(by: "createdAt", descending: false).getDocuments()
        } catch {
            snap = try await query.getDocuments()
        }
        
        let weeks = try snap.documents.compactMap { try $0.data(as: TrainingWeekFS.self) }
        
        return weeks.sorted { a, b in
            a.weekTitle.localizedCaseInsensitiveCompare(b.weekTitle) == .orderedAscending
        }
    }
    
    func getDaysForWeek(weekId: String) async throws -> [TrainingDayFS] {
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        
        let snap = try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .collection(TrainingFS.daysSubcollection)
            .order(by: "dayIndex")
            .getDocuments()
        
        return try snap.documents.compactMap { try $0.data(as: TrainingDayFS.self) }
    }
    
    func getDays(for week: TrainingWeekFS) async throws -> [TrainingDayFS] {
        guard let weekId = week.id.map(clean(_:)), !weekId.isEmpty else {
            throw FirestoreRepositoryError.missingWeekId
        }
        return try await getDaysForWeek(weekId: weekId)
    }
    
    func createWeekForStudent(
        studentId: String,
        teacherId: String,
        title: String,
        categoryRaw: String,
        startDate: Date,
        endDate: Date,
        isPublished: Bool = true
    ) async throws -> String {
        
        let cleanStudentId = clean(studentId)
        let cleanTeacherId = clean(teacherId)
        
        guard !cleanStudentId.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !cleanTeacherId.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let payload: [String: Any] = [
            "studentId": cleanStudentId,
            "teacherId": cleanTeacherId,
            "title": cleanTitle,
            "weekTitle": cleanTitle,
            "categoryRaw": categoryRaw,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "isPublished": isPublished,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        let ref = db.collection(TrainingFS.weeksCollection).document()
        try await ref.setData(payload, merge: true)
        
        return ref.documentID
    }
    
    func upsertDay(
        weekId: String,
        dayId: String? = nil,
        dayIndex: Int,
        dayName: String,
        date: Date,
        title: String,
        description: String,
        blocks: [BlockFS] = []
    ) async throws -> String {
        
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let ref: DocumentReference
        if let dayId, !clean(dayId).isEmpty {
            ref = db.collection(TrainingFS.weeksCollection)
                .document(cleanWeekId)
                .collection(TrainingFS.daysSubcollection)
                .document(clean(dayId))
        } else {
            ref = db.collection(TrainingFS.weeksCollection)
                .document(cleanWeekId)
                .collection(TrainingFS.daysSubcollection)
                .document()
        }
        
        let payload: [String: Any] = [
            "dayIndex": dayIndex,
            "dayName": dayName,
            "date": Timestamp(date: date),
            "title": cleanTitle,
            "description": description,
            "blocks": blocks.map { ["id": $0.id, "name": $0.name, "details": $0.details] },
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await ref.setData(payload, merge: true)
        
        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(["updatedAt": FieldValue.serverTimestamp()], merge: true)
        
        return ref.documentID
    }
    
    func publishWeek(weekId: String, isPublished: Bool) async throws {
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        
        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(
                [
                    "isPublished": isPublished,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }
    
    func updateWeekTitle(weekId: String, newTitle: String) async throws {
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        
        let titleTrim = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrim.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(
                [
                    "weekTitle": titleTrim,
                    "title": titleTrim,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }
    
    func updateWeekDateRangeFromDays(weekId: String) async throws {
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        
        let daysSnap = try await db
            .collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .collection(TrainingFS.daysSubcollection)
            .getDocuments()
        
        guard !daysSnap.documents.isEmpty else { return }
        
        var dates: [Date] = []
        dates.reserveCapacity(daysSnap.documents.count)
        
        for doc in daysSnap.documents {
            let data = doc.data()
            
            if let ts = data["date"] as? Timestamp {
                dates.append(ts.dateValue())
            } else if let d = data["date"] as? Date {
                dates.append(d)
            }
        }
        
        guard let minDate = dates.min(), let maxDate = dates.max() else { return }
        
        try await db
            .collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(
                [
                    "startDate": Timestamp(date: minDate),
                    "endDate": Timestamp(date: maxDate),
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }
    
    // MARK: - Operações de Deleção
    func deleteTrainingWeekCascade(weekId: String) async throws {
        let w = clean(weekId)
        guard !w.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        
        let weekRef = db.collection(TrainingFS.weeksCollection).document(w)
        
        // 1) Deletar days
        let daysSnap = try await weekRef.collection(TrainingFS.daysSubcollection).getDocuments()
        for doc in daysSnap.documents {
            try await doc.reference.delete()
        }
        
        // 2) Deletar student_progress
        let progressSnap = try await weekRef.collection("student_progress").getDocuments()
        for doc in progressSnap.documents {
            try await doc.reference.delete()
        }
        
        // 3) Deletar semana
        try await weekRef.delete()
    }
    
    func deleteTrainingDay(weekId: String, dayId: String) async throws {
        let w = clean(weekId)
        let d = clean(dayId)
        
        guard !w.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        guard !d.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        try await db.collection(TrainingFS.weeksCollection)
            .document(w)
            .collection(TrainingFS.daysSubcollection)
            .document(d)
            .delete()
        
        try await db.collection(TrainingFS.weeksCollection)
            .document(w)
            .setData(["updatedAt": FieldValue.serverTimestamp()], merge: true)
    }
    
    func hasAnyWeeksForStudent(studentId: String) async throws -> Bool {
        let s = clean(studentId)
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        
        let snap = try await db.collection(TrainingFS.weeksCollection)
            .whereField("studentId", isEqualTo: s)
            .limit(to: 1)
            .getDocuments()
        
        return !snap.documents.isEmpty
    }
}
