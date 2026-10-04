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
                return AppLocalization.string(
                    "dashboard.greeting.student_fallback",
                    locale: locale
                )
            case .teacher:
                return AppLocalization.string(
                    "dashboard.greeting.teacher_fallback",
                    locale: locale
                )
            }
        }

        let format = AppLocalization.string("dashboard.greeting.named", locale: locale)
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
        switch self {
        case .today:
            AppLocalization.string("dashboard.day.today", locale: locale)
        case .tomorrow:
            AppLocalization.string("dashboard.day.tomorrow", locale: locale)
        }
    }
}
