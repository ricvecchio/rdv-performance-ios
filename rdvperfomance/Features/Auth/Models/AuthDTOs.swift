// AuthDTOs.swift — DTOs e enums usados no fluxo de autenticação e cadastro
import Foundation

// Tipo de usuário no sistema
enum UserTypeDTO: String, Codable, CaseIterable {
    case TRAINER
    case STUDENT
}

// Áreas de foco possíveis para planos/usuarios
enum FocusAreaDTO: String, Codable, CaseIterable {
    case CROSSFIT, GYM, HOME, FUNCTIONAL, OTHER
}

// Tipos de plano disponíveis
enum PlanTypeDTO: String, Codable, CaseIterable {
    case FREE, BRONZE, SILVER, GOLD
}

// Dados do formulário de registro enviados para Auth/Firestore
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
