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
    case teacherStudentsList(TreinoTipo)
    case teacherStudentDetail(Student, TreinoTipo)

    // Aluno
    case studentAgenda(studentId: String, studentName: String)
    case studentWeekDetail(studentId: String, weekId: String, weekTitle: String)

    // ✅ Futuras rotas do professor (publicar semana/dia)
    // (Vamos usar depois quando você criar as telas)
    case createTrainingWeek(category: TreinoTipo)
    case createTrainingDay(weekId: String, category: TreinoTipo)
}

