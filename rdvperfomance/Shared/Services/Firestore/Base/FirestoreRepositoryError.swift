import Foundation

enum FirestoreRepositoryError: LocalizedError {
    case missingWeekId
    case missingUserId
    case missingStudentId
    case missingTeacherId
    case invalidData
    case writeFailed
    case notFound
    case weekNotStarted
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingWeekId:
            return AppLocalization.string(
                "firestore_repository.errors.missing_week_id",
                locale: Self.localizationLocale
            )
        case .missingUserId:
            return AppLocalization.string(
                "firestore_repository.errors.missing_user_id",
                locale: Self.localizationLocale
            )
        case .missingStudentId:
            return AppLocalization.string(
                "firestore_repository.errors.missing_student_id",
                locale: Self.localizationLocale
            )
        case .missingTeacherId:
            return AppLocalization.string(
                "firestore_repository.errors.missing_teacher_id",
                locale: Self.localizationLocale
            )
        case .invalidData:
            return AppLocalization.string(
                "firestore_repository.errors.invalid_data",
                locale: Self.localizationLocale
            )
        case .writeFailed:
            return AppLocalization.string(
                "firestore_repository.errors.write_failed",
                locale: Self.localizationLocale
            )
        case .notFound:
            return AppLocalization.string(
                "firestore_repository.errors.not_found",
                locale: Self.localizationLocale
            )
        case .weekNotStarted:
            return AppLocalization.string(
                "firestore_repository.errors.week_not_started",
                locale: Self.localizationLocale
            )
        case .deleteFailed(let details):
            let format = AppLocalization.string(
                "firestore_repository.errors.delete_failed",
                locale: Self.localizationLocale
            )
            return String(
                format: format,
                locale: Self.localizationLocale,
                arguments: [details]
            )
        }
    }

    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }
}
