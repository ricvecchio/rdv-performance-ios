import Foundation

// MARK: - ProgressGameMode
// Define de onde as métricas virão.
enum ProgressGameMode: Hashable {
    case preview
    case teacherStudent(studentId: String, displayName: String?)
    case studentMe(studentId: String, displayName: String?)
}
