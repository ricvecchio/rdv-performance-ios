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
                return String(localized: "dashboard.greeting.student", locale: locale)
            case .teacher:
                return String(localized: "dashboard.greeting.teacher", locale: locale)
            }
        }

        let format = String(localized: "dashboard.greeting.named", locale: locale)
        return String(format: format, locale: locale, arguments: [trimmedName])
    }
}

enum DashboardSection {
    case agenda

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .agenda:
            "dashboard.section.agenda"
        }
    }
}

enum DashboardAgendaDay {
    case today
    case tomorrow

    func title(locale: Locale) -> String {
        switch self {
        case .today:
            String(localized: "dashboard.day.today", locale: locale)
        case .tomorrow:
            String(localized: "dashboard.day.tomorrow", locale: locale)
        }
    }
}

enum DashboardLocalizationDiagnostics {
    static func appLanguageChanged(_ identifier: String) {
        #if DEBUG
        print("[Localization] appLanguage=\(identifier) environmentLocale=\(Locale(identifier: identifier).identifier)")
        #endif
    }

    static func dashboardAppeared(
        screen: String,
        locale: Locale,
        hasUserName: Bool
    ) {
        #if DEBUG
        print(
            "[Localization] screen=\(screen) locale=\(locale.identifier) " +
            "hasUserName=\(hasUserName) " +
            "agenda=\(String(localized: "dashboard.section.agenda", locale: locale)) " +
            "today=\(DashboardAgendaDay.today.title(locale: locale)) " +
            "tomorrow=\(DashboardAgendaDay.tomorrow.title(locale: locale))"
        )
        #endif
    }
}
