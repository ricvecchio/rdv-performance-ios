import Foundation

// MARK: - Tipos de conteúdo (Central de Ajuda / Privacidade / Termos)
enum InfoLegalKind: String, Hashable {
    case helpCenter
    case privacyPolicy
    case termsOfUse
}

// MARK: - Rotas do app
enum AppRoute: Hashable {

    // Base
    case login
    case home
    case sobre

    // Treinos
    case treinos(TreinoTipo)
    case crossfitMenu

    // Perfil / Settings
    case perfil
    case configuracoes

    case editarPerfil
    case alterarSenha
    case excluirConta

    // ✅ Tela única: Ajuda / Privacidade / Termos
    case infoLegal(InfoLegalKind)

    // Auth
    case accountTypeSelection
    case registerStudent
    case registerTrainer

    // Professor
    case teacherStudentsList(selectedCategory: TreinoTipo, initialFilter: TreinoTipo?)
    case teacherStudentDetail(AppUser, TreinoTipo)
    case teacherDashboard(category: TreinoTipo)
    case teacherLinkStudent(category: TreinoTipo)

    // Aluno
    case studentAgenda(studentId: String, studentName: String)
    case studentWeekDetail(studentId: String, weekId: String, weekTitle: String)
    case studentDayDetail(weekId: String, day: TrainingDayFS, weekTitle: String)

    // Publicar treinos
    case createTrainingWeek(student: AppUser, category: TreinoTipo)
    case createTrainingDay(weekId: String, category: TreinoTipo)
}

