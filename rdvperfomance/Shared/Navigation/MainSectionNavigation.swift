import SwiftUI

enum StudentMainSection: Hashable {
    case agenda
    case records
    case profile
}

enum TeacherMainSection: Hashable {
    case home
    case students
    case profile
}

private struct SelectStudentMainSectionKey: EnvironmentKey {
    static let defaultValue: (StudentMainSection) -> Void = { _ in }
}

private struct SelectTeacherMainSectionKey: EnvironmentKey {
    static let defaultValue: (TeacherMainSection) -> Void = { _ in }
}

extension EnvironmentValues {
    var selectStudentMainSection: (StudentMainSection) -> Void {
        get { self[SelectStudentMainSectionKey.self] }
        set { self[SelectStudentMainSectionKey.self] = newValue }
    }

    var selectTeacherMainSection: (TeacherMainSection) -> Void {
        get { self[SelectTeacherMainSectionKey.self] }
        set { self[SelectTeacherMainSectionKey.self] = newValue }
    }
}
