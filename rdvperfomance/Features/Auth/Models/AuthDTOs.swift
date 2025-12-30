import Foundation

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

/// Dados usados para cadastro (FirebaseAuth + Firestore)
struct RegisterFormDTO: Codable {
    let name: String
    let email: String
    let password: String
    let phone: String?

    let userType: UserTypeDTO
    let focusArea: String?
    let planType: String

    // TRAINER
    let cref: String?
    let bio: String?
    let gymName: String?

    // STUDENT
    let defaultCategory: String?
    let active: Bool?
}

