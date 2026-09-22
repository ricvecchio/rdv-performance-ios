import SwiftUI

enum TeacherMainSection: Hashable {
    case home
    case students
    case workouts
    case profile
}

private struct SelectStudentMainSectionKey: EnvironmentKey {
    static let defaultValue: (StudentMainSection) -> Void = { _ in }
}

private struct SelectTeacherMainSectionKey: EnvironmentKey {
    static let defaultValue: (TeacherMainSection) -> Void = { _ in }
}

private struct TeacherMainSectionKey: EnvironmentKey {
    static let defaultValue: TeacherMainSection = .home
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

    var teacherMainSection: TeacherMainSection {
        get { self[TeacherMainSectionKey.self] }
        set { self[TeacherMainSectionKey.self] = newValue }
    }
}
