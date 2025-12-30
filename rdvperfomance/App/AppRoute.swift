import SwiftUI

// MARK: - Rotas do app
// Define todas as rotas possíveis da navegação via NavigationStack
enum AppRoute: Hashable {

    // MARK: - Fluxo Base
    case login
    case home
    case sobre
    case perfil
    case configuracoes

    // MARK: - Treinos
    case treinos(TreinoTipo)
    case crossfitMenu

    // MARK: - Cadastro
    case accountTypeSelection
    case registerStudent
    case registerTrainer

    // MARK: - Fluxo PROFESSOR
    /// Tela 3 – Lista de alunos após selecionar categoria
    case teacherStudentsList(TreinoTipo)

    /// Tela 4 – Perfil do aluno selecionado
    case teacherStudentDetail(
        student: Student,
        category: TreinoTipo
    )

    // MARK: - Fluxo ALUNO
    /// Tela principal do aluno (Agenda / Treinos)
    case studentAgenda

    /// Detalhe da semana de treino
    case studentWeekDetail(TrainingWeek)
}

