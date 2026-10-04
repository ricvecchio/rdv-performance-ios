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
            return AppLocalization.string("library.crossfit.girls_wods", locale: Self.localizationLocale)
        case .heroTributeWorkouts:
            return AppLocalization.string("library.crossfit.hero_tribute_workouts", locale: Self.localizationLocale)
        case .competicoesOficiais:
            return AppLocalization.string("library.crossfit.official_competitions", locale: Self.localizationLocale)
        case .formatosWod:
            return AppLocalization.string("library.crossfit.wod_formats", locale: Self.localizationLocale)
        case .formatoSocial:
            return AppLocalization.string("library.crossfit.social_format", locale: Self.localizationLocale)
        case .opens:
            return AppLocalization.string("library.crossfit.opens", locale: Self.localizationLocale)
        case .meusTreinos:
            return AppLocalization.string("workouts.my_workouts", locale: Self.localizationLocale)
        }
    }

    var firestoreKey: String { rawValue }

    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }
}

enum TeacherWorkoutsMode: Hashable {
    case library
    case create
}

enum TeacherWorkoutTemplatesMode: Hashable {
    case manage
    case attach
}

struct TeacherSendWorkoutVideo: Hashable {
    let id: String
    let title: String
    let url: String
    let videoId: String
    let categoryRawValue: String

    init(video: TeacherYoutubeVideo) {
        id = video.id
        title = video.title
        url = video.url
        videoId = video.videoId
        categoryRawValue = video.category.rawValue
    }

    var video: TeacherYoutubeVideo? {
        guard let category = TeacherYoutubeVideoCategory(rawValue: categoryRawValue) else {
            return nil
        }

        return TeacherYoutubeVideo(
            id: id,
            title: title,
            url: url,
            videoId: videoId,
            category: category
        )
    }
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
    case idioma
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
    case teacherMessage(student: AppUser, category: TreinoTipo)
    case teacherFeedbacks(student: AppUser, category: TreinoTipo)

    case studentWorkouts(
        studentId: String,
        studentName: String,
        initialExpandedWeekId: String? = nil,
        initialExpandedDayId: String? = nil
    )
    case studentDayDetail(weekId: String, day: TrainingDayFS, weekTitle: String)
    case studentMessages(category: TreinoTipo)
    case studentFeedbacks(category: TreinoTipo)
    case studentTeachers(studentEmail: String)

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
    case studentVideos
    case teacherPersonalRecords(category: TreinoTipo)

    case createTrainingWeek(student: AppUser, category: TreinoTipo)
    case createTrainingDay(weekId: String, category: TreinoTipo)

    case teacherMyWorkouts(category: TreinoTipo, mode: TeacherWorkoutsMode = .library)
    case teacherCrossfitLibrary(
        section: CrossfitLibrarySection,
        mode: TeacherWorkoutsMode = .library,
        templateMode: TeacherWorkoutTemplatesMode = .manage
    )

    // ✅ NOVO: bibliotecas/menus para separar blocos por músculo
    case teacherAcademiaLibrary(
        mode: TeacherWorkoutsMode = .library,
        templateMode: TeacherWorkoutTemplatesMode = .manage
    )
    case teacherEmCasaLibrary(
        mode: TeacherWorkoutsMode = .library,
        templateMode: TeacherWorkoutTemplatesMode = .manage
    )

    case teacherWorkoutTemplates(
        category: TreinoTipo,
        sectionKey: String,
        sectionTitle: String,
        mode: TeacherWorkoutTemplatesMode = .manage
    )
    case teacherSendWorkout(
        preselectedStudentID: String? = nil,
        startsAtWorkout: Bool = false,
        preselectedTemplate: WorkoutTemplateFS? = nil,
        preselectedVideo: TeacherSendWorkoutVideo? = nil
    )
    case teacherImportWorkouts(category: TreinoTipo)
    case teacherImportVideos(category: TreinoTipo)

    case createCrossfitWOD(category: TreinoTipo, sectionKey: String, sectionTitle: String)
    case createTreinoAcademia(category: TreinoTipo, sectionKey: String, sectionTitle: String)
    case createTreinoCasa(category: TreinoTipo, sectionKey: String, sectionTitle: String)
}
