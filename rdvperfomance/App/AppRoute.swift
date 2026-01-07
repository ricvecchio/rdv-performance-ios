// AppRoute.swift — Definição das rotas do aplicativo e tipos de conteúdo
import Foundation

// Tipo de conteúdo legal/ajuda
enum InfoLegalKind: String, Hashable {
    case helpCenter
    case privacyPolicy
    case termsOfUse
}

// Rotas principais do aplicativo
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

    // Tela única: Ajuda / Privacidade / Termos
    case infoLegal(InfoLegalKind)

    // Auth
    case accountTypeSelection
    case registerStudent
    case registerTrainer

    // Developer / Demos (não intrusivas)
    case mapFeature
    case spriteDemo
    case arDemo

    // Teacher map (Mapa da Academia) — disponível para professores
    case teacherMap

    // Professor
    case teacherStudentsList(selectedCategory: TreinoTipo, initialFilter: TreinoTipo?)
    case teacherStudentDetail(AppUser, TreinoTipo)
    case teacherDashboard(category: TreinoTipo)
    case teacherLinkStudent(category: TreinoTipo)
    case teacherSendMessage(student: AppUser, category: TreinoTipo)
    case teacherFeedbacks(student: AppUser, category: TreinoTipo)

    // Aluno
    case studentAgenda(studentId: String, studentName: String)
    case studentWeekDetail(studentId: String, weekId: String, weekTitle: String)
    case studentDayDetail(weekId: String, day: TrainingDayFS, weekTitle: String)
    case studentMessages(category: TreinoTipo)
    case studentFeedbacks(category: TreinoTipo)

    // Publicar treinos
    case createTrainingWeek(student: AppUser, category: TreinoTipo)
    case createTrainingDay(weekId: String, category: TreinoTipo)
}
