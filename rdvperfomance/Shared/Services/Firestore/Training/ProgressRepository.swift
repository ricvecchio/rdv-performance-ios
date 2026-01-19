import Foundation
import FirebaseFirestore

final class ProgressRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()
    
    private let progressSubcollection = "student_progress"
    
    func getDayStatusMap(weekId: String, studentId: String) async throws -> [String: Bool] {
        let w = clean(weekId)
        let s = clean(studentId)
        guard !w.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        
        let doc = try await db
            .collection(TrainingFS.weeksCollection)
            .document(w)
            .collection(progressSubcollection)
            .document(s)
            .getDocument()
        
        guard doc.exists else { return [:] }
        
        let data = doc.data() ?? [:]
        return data["completedMap"] as? [String: Bool] ?? [:]
    }
    
    func setDayCompleted(weekId: String, studentId: String, dayId: String, completed: Bool) async throws {
        let w = clean(weekId)
        let s = clean(studentId)
        let d = clean(dayId)
        
        guard !w.isEmpty else { throw FirestoreRepositoryError.missingWeekId }
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !d.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let ref = db
            .collection(TrainingFS.weeksCollection)
            .document(w)
            .collection(progressSubcollection)
            .document(s)
        
        try await ref.setData(
            [
                "studentId": s,
                "updatedAt": FieldValue.serverTimestamp(),
                "completedMap": [d: completed]
            ],
            merge: true
        )
    }
    
    func getWeekProgress(weekId: String, studentId: String) async throws -> (completed: Int, total: Int) {
        let trainingRepo = TrainingRepository()
        let days = try await trainingRepo.getDaysForWeek(weekId: weekId)
        let total = days.count
        
        guard total > 0 else { return (0, 0) }
        
        let map = try await getDayStatusMap(weekId: weekId, studentId: studentId)
        let completed = map.values.filter { $0 }.count
        
        return (completed, total)
    }
    
    func getStudentOverallProgress(studentId: String) async throws -> (percent: Int, completed: Int, total: Int) {
        let s = clean(studentId)
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        
        let trainingRepo = TrainingRepository()
        let weeks = try await trainingRepo.getWeeksForStudent(studentId: s, onlyPublished: true)
        guard !weeks.isEmpty else { return (0, 0, 0) }
        
        var totalDays = 0
        var totalCompleted = 0
        
        try await withThrowingTaskGroup(of: (Int, Int).self) { group in
            for w in weeks {
                guard let weekId = w.id else { continue }
                group.addTask {
                    let p = try await self.getWeekProgress(weekId: weekId, studentId: s)
                    return (p.completed, p.total)
                }
            }
            
            for try await result in group {
                totalCompleted += result.0
                totalDays += result.1
            }
        }
        
        let percent: Int
        if totalDays > 0 {
            percent = Int(((Double(totalCompleted) / Double(totalDays)) * 100.0).rounded())
        } else {
            percent = 0
        }
        
        return (percent, totalCompleted, totalDays)
    }
}
