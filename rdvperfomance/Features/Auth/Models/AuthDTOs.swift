// DTOs e enums para fluxo de autenticação e cadastro
import Foundation

// Define os tipos de usuário disponíveis no sistema
enum UserTypeDTO: String, Codable, CaseIterable {
    case TRAINER
    case STUDENT
}

// Define as áreas de foco para treinos do usuário
enum FocusAreaDTO: String, Codable, CaseIterable {
    case CROSSFIT, GYM, HOME, FUNCTIONAL, OTHER
}

// Define os tipos de planos de assinatura disponíveis
enum PlanTypeDTO: String, Codable, CaseIterable {
    case FREE, BRONZE, SILVER, GOLD
}

// Dados do formulário de registro de usuário
struct RegisterFormDTO: Codable {
    let name: String
    let email: String
    let password: String
    let phone: String?

    let userType: UserTypeDTO
    let focusArea: String?
    let planType: String

    // Campos para TRAINER
    let cref: String?
    let bio: String?
    let gymName: String?

    // Campos para STUDENT
    let defaultCategory: String?
    let active: Bool?
}
