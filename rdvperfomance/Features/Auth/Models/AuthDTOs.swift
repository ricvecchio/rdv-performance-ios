import Foundation

// MARK: - Enums alinhados ao backend
enum UserTypeDTO: String, Codable, CaseIterable {
    case TRAINER
    case STUDENT
}

enum FocusAreaDTO: String, Codable, CaseIterable {
    case CROSSFIT, GYM, HOME, FUNCTIONAL, OTHER
}

enum PlanTypeDTO: String, Codable, CaseIterable {
    case FREE, BRONZE, SILVER, GOLD
}

// MARK: - Request/Response
struct RegisterRequestDTO: Codable {
    let name: String
    let email: String
    let password: String
    let phone: String?

    let userType: UserTypeDTO
    let focusArea: FocusAreaDTO?
    let planType: PlanTypeDTO

    // Campos TRAINER (opcionais no banco; obrigatórios por validação quando TRAINER)
    let cref: String?
    let bio: String?
    let gymName: String?
}

struct RegisterResponseDTO: Codable {
    // Você pode ajustar quando souber o payload real do backend.
    // Mantive genérico para não travar o app.
    let idUser: String?
    let message: String?
}
