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
            return String(localized: "Não foi possível carregar/salvar: weekId está vazio ou nulo.", locale: Self.localizationLocale)
        case .missingUserId:
            return String(localized: "Não foi possível identificar o usuário (uid vazio).", locale: Self.localizationLocale)
        case .missingStudentId:
            return String(localized: "Não foi possível identificar o aluno (studentId vazio).", locale: Self.localizationLocale)
        case .missingTeacherId:
            return String(localized: "Não foi possível identificar o professor (teacherId vazio).", locale: Self.localizationLocale)
        case .invalidData:
            return String(localized: "Dados inválidos para operação no Firestore.", locale: Self.localizationLocale)
        case .writeFailed:
            return String(localized: "Não foi possível salvar os dados no Firestore.", locale: Self.localizationLocale)
        case .notFound:
            return String(localized: "Registro não encontrado no Firestore.", locale: Self.localizationLocale)
        case .weekNotStarted:
            return String(localized: "Esta semana ainda não começou e não pode receber conclusões.", locale: Self.localizationLocale)
        case .deleteFailed(let details):
            let format = String(localized: "Falha ao excluir: %@", locale: Self.localizationLocale)
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
