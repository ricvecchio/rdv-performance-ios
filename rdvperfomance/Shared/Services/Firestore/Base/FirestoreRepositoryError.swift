import Foundation

enum FirestoreRepositoryError: LocalizedError {
    case missingWeekId
    case missingUserId
    case missingStudentId
    case missingTeacherId
    case invalidData
    case writeFailed
    case notFound
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingWeekId:
            return "Não foi possível carregar/salvar: weekId está vazio ou nulo."
        case .missingUserId:
            return "Não foi possível identificar o usuário (uid vazio)."
        case .missingStudentId:
            return "Não foi possível identificar o aluno (studentId vazio)."
        case .missingTeacherId:
            return "Não foi possível identificar o professor (teacherId vazio)."
        case .invalidData:
            return "Dados inválidos para operação no Firestore."
        case .writeFailed:
            return "Não foi possível salvar os dados no Firestore."
        case .notFound:
            return "Registro não encontrado no Firestore."
        case .deleteFailed(let details):
            return "Falha ao excluir: \(details)"
        }
    }
}
