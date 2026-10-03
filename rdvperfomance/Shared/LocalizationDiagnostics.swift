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
        let localization = locale.identifier
        let hasStringTable = Bundle.main.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: localization
        ) != nil
        let availableLocalizations = Bundle.main.localizations.sorted().joined(separator: ",")
        let message = "[i18n] context=LocalizationCatalog locale=\(localization) key=Localizable.strings value=present:\(hasStringTable) available:\(availableLocalizations)"
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
#endif
}
