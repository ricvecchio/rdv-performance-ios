import Foundation
import SwiftUI

enum DashboardGreetingAudience {
    case student
    case teacher
}

enum DashboardGreeting {
    static func text(
        name: String?,
        audience: DashboardGreetingAudience,
        locale: Locale
    ) -> String {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty else {
            switch audience {
            case .student:
                let value = AppLocalization.string(
                    "dashboard.greeting.student_fallback",
                    locale: locale
                )
                LocalizationDiagnostics.resolved(
                    context: "DashboardGreeting.studentFallback",
                    locale: locale,
                    key: "dashboard.greeting.student_fallback",
                    value: value
                )
                return value
            case .teacher:
                let value = AppLocalization.string(
                    "dashboard.greeting.teacher_fallback",
                    locale: locale
                )
                LocalizationDiagnostics.resolved(
                    context: "DashboardGreeting.teacherFallback",
                    locale: locale,
                    key: "dashboard.greeting.teacher_fallback",
                    value: value
                )
                return value
            }
        }

        let format = AppLocalization.string("dashboard.greeting.named", locale: locale)
        LocalizationDiagnostics.resolved(
            context: "DashboardGreeting.named",
            locale: locale,
            key: "dashboard.greeting.named",
            value: format
        )
        return String(format: format, locale: locale, arguments: [trimmedName])
    }
}

enum DashboardMode {
    case crossfit
    case agenda

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .crossfit:
            "dashboard.mode.crossfit"
        case .agenda:
            "dashboard.mode.agenda"
        }
    }
}

enum DashboardAgendaDay {
    case today
    case tomorrow

    func title(locale: Locale) -> String {
        let key: String
        let value: String
        switch self {
        case .today:
            key = "dashboard.day.today"
            value = AppLocalization.string("dashboard.day.today", locale: locale)
        case .tomorrow:
            key = "dashboard.day.tomorrow"
            value = AppLocalization.string("dashboard.day.tomorrow", locale: locale)
        }
        LocalizationDiagnostics.resolved(
            context: "DashboardAgendaDay",
            locale: locale,
            key: key,
            value: value
        )
        return value
    }
}
