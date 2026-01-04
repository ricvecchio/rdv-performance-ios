import Foundation

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

    // Auth
    case accountTypeSelection
    case registerStudent
    case registerTrainer

    // Professor
    // ✅ Agora recebe o filtro inicial (nil = Todos)
    case teacherStudentsList(selectedCategory: TreinoTipo, initialFilter: TreinoTipo?)
    case teacherStudentDetail(AppUser, TreinoTipo)
    case teacherDashboard(category: TreinoTipo)

    // ✅ Professor: vincular alunos
    case teacherLinkStudent(category: TreinoTipo)

    // Aluno
    case studentAgenda(studentId: String, studentName: String)
    case studentWeekDetail(studentId: String, weekId: String, weekTitle: String)

    // ✅ Aluno (detalhe do dia) - AGORA PRECISA DO weekId
    case studentDayDetail(weekId: String, day: TrainingDayFS, weekTitle: String)

    // Publicar treinos
    case createTrainingWeek(student: AppUser, category: TreinoTipo)
    case createTrainingDay(weekId: String, category: TreinoTipo)
}

