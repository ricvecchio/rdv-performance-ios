import Foundation

// Define os tipos de conteúdo legal e informativo disponíveis
enum InfoLegalKind: String, Hashable {
    case helpCenter
    case privacyPolicy
    case termsOfUse
}

// Seções de “Meus Treinos” (Crossfit)
enum CrossfitLibrarySection: String, Hashable, CaseIterable {

    // ✅ Girls WODs (antes: benchmarks)
    case benchmarks

    // ✅ NOVO: logo abaixo de Girls WODs
    case heroTributeWorkouts

    case competicoesOficiais
    case formatosWod
    case formatoSocial
    case opens
    case meusTreinos

    var title: String {
        switch self {

        // ✅ ALTERADO: "Benchmarks" -> "Girls WODs"
        case .benchmarks:
            return "Girls WODs"

        // ✅ NOVO
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

    // ✅ Biblioteca de Treinos (Professor)
    case teacherMyWorkouts(category: TreinoTipo)

    // ✅ Biblioteca Crossfit (seções)
    case teacherCrossfitLibrary(section: CrossfitLibrarySection)

    // ✅ Lista de templates (qualquer categoria, por seção)
    case teacherWorkoutTemplates(category: TreinoTipo, sectionKey: String, sectionTitle: String)

    // ✅ NOVO: Importar Vídeos (YouTube) - Professor
    case teacherImportVideos(category: TreinoTipo)

    // ✅ criar template de WOD (Girls WODs)
    case createCrossfitWOD(category: TreinoTipo, sectionKey: String, sectionTitle: String)

    // ✅ NOVO: criar Treino Academia
    case createTreinoAcademia(category: TreinoTipo, sectionKey: String, sectionTitle: String)

    // ✅ NOVO: criar Treino em Casa
    case createTreinoCasa(category: TreinoTipo, sectionKey: String, sectionTitle: String)
}

