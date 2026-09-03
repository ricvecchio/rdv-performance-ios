import SwiftUI

struct TeacherRootView: View {
    @AppStorage("ultimoTreinoSelecionado")
    private var lastSelectedTraining: String = TreinoTipo.crossfit.rawValue

    @State private var selectedSection: TeacherMainSection = .home
    @State private var homePath: [AppRoute] = []
    @State private var studentsPath: [AppRoute] = []
    @State private var profilePath: [AppRoute] = []

    private var category: TreinoTipo {
        TreinoTipo(rawValue: lastSelectedTraining) ?? .crossfit
    }

    var body: some View {
        Group {
            switch selectedSection {
            case .home:
                NavigationStack(path: $homePath) {
                    TeacherDashboardView(path: $homePath, category: category)
                        .navigationDestination(for: AppRoute.self, destination: teacherDestination)
                }
            case .students:
                NavigationStack(path: $studentsPath) {
                    TeacherStudentsListView(path: $studentsPath, selectedCategory: category, initialFilter: nil, onBack: { select(.home) })
                        .navigationDestination(for: AppRoute.self, destination: teacherDestination)
                }
            case .profile:
                NavigationStack(path: $profilePath) {
                    ProfileView(path: $profilePath, onBack: { select(.home) })
                        .navigationDestination(for: AppRoute.self, destination: teacherDestination)
                }
            }
        }
        .environment(\.selectTeacherMainSection, select)
    }

    private func select(_ section: TeacherMainSection) {
        guard selectedSection != section else { return }

        switch section {
        case .home: homePath.removeAll()
        case .students: studentsPath.removeAll()
        case .profile: profilePath.removeAll()
        }

        selectedSection = section
    }

    @ViewBuilder
    private func teacherDestination(_ route: AppRoute) -> some View {
        switch route {
        case .teacherStudentDetail(let student, let category):
            TeacherStudentDetailView(path: destinationPath, student: student, category: category)
        case .teacherMessage(let student, let category):
            TeacherMessageView(path: destinationPath, student: student, category: category)
        case .teacherFeedbacks(let student, let category):
            TeacherFeedbacksView(path: destinationPath, student: student, category: category)
        case .createTrainingWeek(let student, let category):
            CreateTrainingWeekView(path: destinationPath, student: student, category: category)
        case .createTrainingDay(let weekId, let category):
            CreateTrainingDayView(path: destinationPath, weekId: weekId, category: category)
        case .teacherMyWorkouts(let category):
            TeacherMyWorkoutsView(path: destinationPath, category: category)
        case .teacherCrossfitLibrary(let section):
            TeacherCrossfitLibraryView(path: destinationPath, section: section)
        case .teacherAcademiaLibrary:
            TeacherAcademiaLibraryView(path: destinationPath)
        case .teacherEmCasaLibrary:
            TeacherEmCasaLibraryView(path: destinationPath)
        case .teacherWorkoutTemplates(let category, let sectionKey, let sectionTitle):
            TeacherWorkoutTemplatesView(path: destinationPath, category: category, sectionKey: sectionKey, sectionTitle: sectionTitle)
        case .teacherImportWorkouts(let category):
            TeacherImportWorkoutsView(path: destinationPath, category: category)
        case .teacherImportVideos(let category):
            TeacherImportVideosView(path: destinationPath, category: category)
        case .createCrossfitWOD(let category, let sectionKey, let sectionTitle):
            CreateCrossfitWODView(path: destinationPath, category: category, sectionKey: sectionKey, sectionTitle: sectionTitle)
        case .createTreinoAcademia(let category, let sectionKey, let sectionTitle):
            CreateTreinoAcademiaView(path: destinationPath, category: category, sectionKey: sectionKey, sectionTitle: sectionTitle)
        case .createTreinoCasa(let category, let sectionKey, let sectionTitle):
            CreateTreinoCasaView(path: destinationPath, category: category, sectionKey: sectionKey, sectionTitle: sectionTitle)
        case .studentAgenda(let studentId, let studentName):
            StudentAgendaView(path: destinationPath, studentId: studentId, studentName: studentName)
        case .studentWeekDetail(let studentId, let weekId, let weekTitle):
            StudentWeekDetailView(path: destinationPath, studentId: studentId, weekId: weekId, weekTitle: weekTitle)
        case .studentDayDetail(let weekId, let day, let weekTitle):
            StudentDayDetailView(path: destinationPath, weekId: weekId, day: day, weekTitle: weekTitle)
        case .configuracoes:
            SettingsView(path: destinationPath)
        case .editarPerfil:
            EditProfileView(path: destinationPath)
        case .alterarSenha:
            ChangePasswordView(path: destinationPath)
        case .excluirConta:
            DeleteAccountView(path: destinationPath)
        case .sobre:
            AboutView(path: destinationPath)
        case .infoLegal(let kind):
            InfoLegalView(path: destinationPath, kind: kind)
        case .spriteDemo:
            SpriteDemoView(path: destinationPath)
        default:
            EmptyView()
        }
    }

    private var destinationPath: Binding<[AppRoute]> {
        switch selectedSection {
        case .home: $homePath
        case .students: $studentsPath
        case .profile: $profilePath
        }
    }
}
