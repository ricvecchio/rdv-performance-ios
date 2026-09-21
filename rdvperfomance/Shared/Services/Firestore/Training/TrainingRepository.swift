import Foundation
import FirebaseFirestore

final class TrainingRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()
    
    func getWeeksForStudent(
        studentId: String,
        teacherId: String? = nil,
        categoryRaw: String? = nil,
        onlyPublished: Bool = true
    ) async throws -> [TrainingWeekFS] {
        let cleanStudentId = clean(studentId)
        guard !cleanStudentId.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        let cleanTeacherId = teacherId.map(clean(_:)) ?? ""
        let cleanCategoryRaw = categoryRaw.map(normalizedCategory(_:)) ?? ""
        
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
        
        return weeks
            .filter { week in
                (cleanTeacherId.isEmpty || clean(week.teacherId) == cleanTeacherId)
                    && (cleanCategoryRaw.isEmpty || normalizedCategory(week.categoryRaw) == cleanCategoryRaw)
            }
            .sorted { a, b in
            a.weekTitle.localizedCaseInsensitiveCompare(b.weekTitle) == .orderedAscending
        }
    }

    func getPublishedWeeksForTeacher(teacherId: String) async throws -> [TrainingWeekFS] {
        let cleanTeacherId = clean(teacherId)
        guard !cleanTeacherId.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        let snap = try await db.collection(TrainingFS.weeksCollection)
            .whereField("teacherId", isEqualTo: cleanTeacherId)
            .getDocuments()

        return try snap.documents
            .compactMap { try $0.data(as: TrainingWeekFS.self) }
            .filter(\.isPublished)
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
        isPublished: Bool = true,
        documentId: String? = nil
    ) async throws -> String {
        
        let cleanStudentId = clean(studentId)
        let cleanTeacherId = clean(teacherId)
        
        guard !cleanStudentId.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !cleanTeacherId.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw FirestoreRepositoryError.invalidData }
        let cleanCategoryRaw = clean(categoryRaw)
        guard !cleanCategoryRaw.isEmpty else { throw FirestoreRepositoryError.invalidData }

        let (normalizedStartDate, normalizedEndDate) = try calendarWeek(containing: startDate)
        
        let payload: [String: Any] = [
            "studentId": cleanStudentId,
            "teacherId": cleanTeacherId,
            "title": cleanTitle,
            "weekTitle": cleanTitle,
            "categoryRaw": cleanCategoryRaw,
            "startDate": Timestamp(date: normalizedStartDate),
            "endDate": Timestamp(date: normalizedEndDate),
            "isPublished": isPublished,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        let cleanDocumentId = documentId.map(clean(_:)) ?? ""
        let ref = cleanDocumentId.isEmpty
            ? db.collection(TrainingFS.weeksCollection).document()
            : db.collection(TrainingFS.weeksCollection).document(cleanDocumentId)
        try await ref.setData(payload, merge: true)
        
        return ref.documentID
    }

    func resolveOrCreateWeekForStudent(
        studentId: String,
        teacherId: String,
        categoryRaw: String,
        date: Date
    ) async throws -> (weekId: String, startDate: Date) {
        let cleanStudentId = clean(studentId)
        let cleanTeacherId = clean(teacherId)
        guard !cleanStudentId.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !cleanTeacherId.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: date)
        let cleanCategoryRaw = clean(categoryRaw)
        let normalizedCategoryRaw = normalizedCategory(cleanCategoryRaw)
        guard !normalizedCategoryRaw.isEmpty else { throw FirestoreRepositoryError.invalidData }
        let (weekStartDate, weekEndDate) = try calendarWeek(containing: selectedDate)
        let existingWeeks = try await getWeeksForStudent(
            studentId: cleanStudentId,
            teacherId: cleanTeacherId,
            categoryRaw: normalizedCategoryRaw,
            onlyPublished: false
        )

        let matchingWeeks = existingWeeks.compactMap { week -> (weekId: String, startDate: Date)? in
            guard let weekId = week.id.map(clean(_:)),
                  !weekId.isEmpty,
                  clean(week.studentId) == cleanStudentId,
                  clean(week.teacherId) == cleanTeacherId,
                  normalizedCategory(week.categoryRaw) == normalizedCategoryRaw,
                  let startDate = week.startDate,
                  let endDate = week.endDate else {
                return nil
            }

            let start = calendar.startOfDay(for: startDate)
            let end = calendar.startOfDay(for: endDate)
            guard calendar.isDate(start, inSameDayAs: weekStartDate),
                  calendar.isDate(end, inSameDayAs: weekEndDate),
                  selectedDate >= start,
                  selectedDate <= end else {
                return nil
            }
            return (weekId, start)
        }
        .sorted { $0.startDate > $1.startDate }

        if let matchingWeek = matchingWeeks.first {
            return matchingWeek
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        let title = "Semana \(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"

        let identifierFormatter = DateFormatter()
        identifierFormatter.locale = Locale(identifier: "en_US_POSIX")
        identifierFormatter.calendar = calendar
        identifierFormatter.dateFormat = "yyyyMMdd"
        let automaticWeekId = "automatic-\(cleanStudentId)-\(cleanTeacherId)-\(automaticIdentifierComponent(normalizedCategoryRaw))-\(identifierFormatter.string(from: weekStartDate))"
        _ = try await createWeekForStudent(
            studentId: cleanStudentId,
            teacherId: cleanTeacherId,
            title: title,
            categoryRaw: cleanCategoryRaw,
            startDate: weekStartDate,
            endDate: weekEndDate,
            isPublished: true,
            documentId: automaticWeekId
        )

        return (automaticWeekId, weekStartDate)
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

    private func calendarWeek(containing date: Date) throws -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday + 5) % 7
        guard let startDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: selectedDate),
              let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) else {
            throw FirestoreRepositoryError.invalidData
        }
        return (calendar.startOfDay(for: startDate), calendar.startOfDay(for: endDate))
    }

    private func normalizedCategory(_ categoryRaw: String) -> String {
        clean(categoryRaw).lowercased()
    }

    private func automaticIdentifierComponent(_ value: String) -> String {
        value.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? String($0) : "-" }
            .joined()
    }
}
