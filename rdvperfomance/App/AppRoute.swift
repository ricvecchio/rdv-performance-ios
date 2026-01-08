import Foundation

// Define os tipos de conteúdo legal e informativo disponíveis
enum InfoLegalKind: String, Hashable {
    case helpCenter
    case privacyPolicy
    case termsOfUse
}

// Representa todas as rotas de navegação disponíveis no aplicativo
enum AppRoute: Hashable {

    case login
    case home
    case sobre

    case treinos(TreinoTipo)
    case crossfitMenu

    case perfil
    case configuracoes
    case editarPerfil
    case alterarSenha
    case excluirConta

    case infoLegal(InfoLegalKind)

    case accountTypeSelection
    case registerStudent
    case registerTrainer

    case mapFeature
    case spriteDemo
    case arDemo

    case progressGame(mode: ProgressGameMode)
    case arExercise(weekId: String, dayId: String)

    case teacherStudentsList(selectedCategory: TreinoTipo, initialFilter: TreinoTipo?)
    case teacherStudentDetail(AppUser, TreinoTipo)
    case teacherDashboard(category: TreinoTipo)
    case teacherLinkStudent(category: TreinoTipo)
    case teacherSendMessage(student: AppUser, category: TreinoTipo)
    case teacherFeedbacks(student: AppUser, category: TreinoTipo)

    case studentAgenda(studentId: String, studentName: String)
    case studentWeekDetail(studentId: String, weekId: String, weekTitle: String)
    case studentDayDetail(weekId: String, day: TrainingDayFS, weekTitle: String)
    case studentMessages(category: TreinoTipo)
    case studentFeedbacks(category: TreinoTipo)

    case createTrainingWeek(student: AppUser, category: TreinoTipo)
    case createTrainingDay(weekId: String, category: TreinoTipo)
}

