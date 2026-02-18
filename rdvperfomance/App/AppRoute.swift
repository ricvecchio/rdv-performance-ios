import Foundation

// Define os tipos de conteúdo legal e informativo disponíveis
enum InfoLegalKind: String, Hashable {
    case helpCenter
    case privacyPolicy
    case termsOfUse
}

// Seções de “Meus Treinos” (Crossfit)
enum CrossfitLibrarySection: String, Hashable, CaseIterable {

    case benchmarks
    case heroTributeWorkouts
    case competicoesOficiais
    case formatosWod
    case formatoSocial
    case opens
    case meusTreinos

    var title: String {
        switch self {
        case .benchmarks:
            return "Girls WODs"
        case .heroTributeWorkouts:
            return "Hero & Tribute Workouts"
        case .competicoesOficiais:
            return "Competições Oficiais"
        case .formatosWod:
            return "Formatos de WOD"
        case .formatoSocial:
            return "Formato Social"
        case .opens:
            return "Open’s"
        case .meusTreinos:
            return "Meus Treinos"
        }
    }

    var firestoreKey: String { rawValue }
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

    case spriteDemo

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

    case studentPersonalRecords
    case studentPersonalRecordsBarbell
    case studentPersonalRecordsGymnastic
    case studentPersonalRecordsEndurance
    case studentPersonalRecordsNotables
    case studentPersonalRecordsGirls
    case studentPersonalRecordsOpen
    case studentPersonalRecordsHeroes
    case studentPersonalRecordsCampeonatos
    case studentPersonalRecordsCrossfitGames

    case createTrainingWeek(student: AppUser, category: TreinoTipo)
    case createTrainingDay(weekId: String, category: TreinoTipo)

    case teacherMyWorkouts(category: TreinoTipo)
    case teacherCrossfitLibrary(section: CrossfitLibrarySection)

    // ✅ NOVO: bibliotecas/menus para separar blocos por músculo
    case teacherAcademiaLibrary
    case teacherEmCasaLibrary

    case teacherWorkoutTemplates(category: TreinoTipo, sectionKey: String, sectionTitle: String)
    case teacherImportWorkouts(category: TreinoTipo)
    case teacherImportVideos(category: TreinoTipo)

    case createCrossfitWOD(category: TreinoTipo, sectionKey: String, sectionTitle: String)
    case createTreinoAcademia(category: TreinoTipo, sectionKey: String, sectionTitle: String)
    case createTreinoCasa(category: TreinoTipo, sectionKey: String, sectionTitle: String)
}

