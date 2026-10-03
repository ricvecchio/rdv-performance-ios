import Foundation
import OSLog

enum LocalizationDiagnostics {
#if DEBUG
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.rdvperformance.app",
        category: "Localization"
    )
    private static let lock = NSLock()
    private static var emittedFingerprints = Set<String>()

    static func resolved(
        context: String,
        locale: Locale,
        key: String,
        value: String? = nil,
        containsUserData: Bool = false
    ) {
        let output = containsUserData ? "<user-data>" : (value ?? "<not-recorded>")
        let message = "[i18n] context=\(context) locale=\(locale.identifier) key=\(key) value=\(output)"
        guard register(message) else { return }
        logger.notice("\(message, privacy: .public)")
        print(message)
    }

    static func catalogAvailability(locale: Locale) {
        let selectedAppLanguage = UserDefaults.standard.string(forKey: "selectedAppLanguage") ?? "<unset>"
        let availableLocalizations = Bundle.main.localizations.sorted().joined(separator: ",")
        let preferredLocalizations = Bundle.main.preferredLocalizations.joined(separator: ",")
        let developmentLocalization = Bundle.main.developmentLocalization ?? "<unset>"

        emit(
            "[i18n] selectedAppLanguage=\(selectedAppLanguage) environmentLocale=\(locale.identifier)"
        )
        emit(
            "[i18n] bundle.localizations=[\(availableLocalizations)] bundle.preferredLocalizations=[\(preferredLocalizations)] bundle.developmentLocalization=\(developmentLocalization)"
        )
    }

    static func runtimeSnapshot(context: String, locale: Locale) {
        catalogAvailability(locale: locale)

        let currentLocaleValues = [
            (
                key: "dashboard.greeting.named",
                value: AppLocalization.string("dashboard.greeting.named", locale: locale)
            ),
            (
                key: "dashboard.day.today",
                value: AppLocalization.string("dashboard.day.today", locale: locale)
            ),
            (
                key: "dashboard.day.tomorrow",
                value: AppLocalization.string("dashboard.day.tomorrow", locale: locale)
            ),
            (
                key: "dashboard.weekly_progress",
                value: AppLocalization.string("dashboard.weekly_progress", locale: locale)
            ),
            (
                key: "student_teachers.link_request.invalid_email",
                value: AppLocalization.string(
                    "student_teachers.link_request.invalid_email",
                    locale: locale
                )
            )
        ]
        for localizedValue in currentLocaleValues {
            resolved(
                context: "\(context).environment",
                locale: locale,
                key: localizedValue.key,
                value: localizedValue.value
            )
        }

        let englishLocale = Locale(identifier: "en")
        let englishControlValues = [
            (
                key: "dashboard.greeting.named",
                value: AppLocalization.string(
                    "dashboard.greeting.named",
                    locale: englishLocale
                )
            ),
            (
                key: "dashboard.day.today",
                value: AppLocalization.string(
                    "dashboard.day.today",
                    locale: englishLocale
                )
            ),
            (
                key: "dashboard.day.tomorrow",
                value: AppLocalization.string(
                    "dashboard.day.tomorrow",
                    locale: englishLocale
                )
            ),
            (
                key: "dashboard.weekly_progress",
                value: AppLocalization.string(
                    "dashboard.weekly_progress",
                    locale: englishLocale
                )
            ),
            (
                key: "student_teachers.link_request.invalid_email",
                value: AppLocalization.string(
                    "student_teachers.link_request.invalid_email",
                    locale: englishLocale
                )
            )
        ]
        for localizedValue in englishControlValues {
            resolved(
                context: "\(context).englishControl",
                locale: englishLocale,
                key: localizedValue.key,
                value: localizedValue.value
            )
        }
    }

    private static func emit(_ message: String) {
        guard register(message) else { return }
        logger.notice("\(message, privacy: .public)")
        print(message)
    }

    private static func register(_ fingerprint: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return emittedFingerprints.insert(fingerprint).inserted
    }
#else
    static func resolved(
        context: String,
        locale: Locale,
        key: String,
        value: String? = nil,
        containsUserData: Bool = false
    ) {}

    static func catalogAvailability(locale: Locale) {}

    static func runtimeSnapshot(context: String, locale: Locale) {}
#endif
}
