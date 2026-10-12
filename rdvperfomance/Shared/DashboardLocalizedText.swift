import Foundation
import SwiftUI

enum DashboardGreetingAudience {
    case student
    case teacher
}

enum DashboardGreeting {
    static func styledText(
        name: String?,
        audience: DashboardGreetingAudience,
        locale: Locale
    ) -> Text {
        let greeting = text(name: name, audience: audience, locale: locale)
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !trimmedName.isEmpty, let nameRange = greeting.range(of: trimmedName) else {
            return Text(greeting).foregroundColor(.white)
        }

        return Text(String(greeting[..<nameRange.lowerBound]))
            .foregroundColor(.white)
            + Text(trimmedName)
                .foregroundColor(Theme.Colors.primaryGreen)
            + Text(String(greeting[nameRange.upperBound...]))
                .foregroundColor(.white)
    }

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
