// Modelos de dados para autenticação e cadastro de usuários
import Foundation

// Tipos de usuário disponíveis no sistema
enum UserTypeDTO: String, Codable, CaseIterable {
    case TRAINER
    case STUDENT
}

// Áreas de foco para os treinos do usuário
enum FocusAreaDTO: String, Codable, CaseIterable {
    case CROSSFIT, GYM, HOME
}

// Dados do formulário de registro completo
struct RegisterFormDTO: Codable {
    let name: String
    let email: String
    let password: String
    let phone: String?

    let userType: UserTypeDTO
    let focusArea: String?

    let cref: String?
    let bio: String?
    let gymName: String?

    let defaultCategory: String?
    let active: Bool?
}
