import SwiftUI

// Container principal de navegação do aplicativo
struct AppRouter: View {

    @State private var path: [AppRoute] = []
    @StateObject private var session = AppSession()

    // ✅ chave já usada no app para lembrar a categoria
    private let ultimoTreinoKey: String = "ultimoTreinoSelecionado"

    // Configura a pilha de navegação com todas as rotas do app
    var body: some View {
        NavigationStack(path: $path) {

            rootView
                .environmentObject(session)

                .navigationDestination(for: AppRoute.self) { route in
                    switch route {

                    case .login:
                        LoginView(path: $path)
                            .environmentObject(session)

                    case .home:
                        guardedHome()

                    case .teacherStudentsList(let selectedCategory, let initialFilter):
                        guardedTeacher {
                            TeacherStudentsListView(
                                path: $path,
                                selectedCategory: selectedCategory,
                                initialFilter: initialFilter
                            )
                        }

                    case .teacherStudentDetail(let student, let category):
                        guardedTeacher {
                            TeacherStudentDetailView(
                                path: $path,
                                student: student,
                                category: category
                            )
                        }

                    case .teacherDashboard(let category):
                        guardedTeacher {
                            TeacherDashboardView(
                                path: $path,
                                category: category
                            )
                        }

                    case .teacherLinkStudent(let category):
                        guardedTeacher {
                            TeacherLinkStudentView(
                                path: $path,
                                category: category
                            )
                        }

                    case .teacherSendMessage(let student, let category):
                        guardedTeacher {
                            TeacherSendMessageView(
                                path: $path,
                                student: student,
                                category: category
                            )
                        }

                    case .teacherFeedbacks(let student, let category):
                        guardedTeacher {
                            TeacherFeedbacksView(
                                path: $path,
                                student: student,
                                category: category
                            )
                        }

                    case .createTrainingWeek(let student, let category):
                        guardedTeacher {
                            CreateTrainingWeekView(
                                path: $path,
                                student: student,
                                category: category
                            )
                        }

                    case .createTrainingDay(let weekId, let category):
                        guardedTeacher {
                            CreateTrainingDayView(
                                path: $path,
                                weekId: weekId,
                                category: category
                            )
                        }

                    case .studentAgenda(let studentId, let studentName):
                        guardedHome {
                            StudentAgendaView(
                                path: $path,
                                studentId: studentId,
                                studentName: studentName
                            )
                        }

                    case .studentWeekDetail(let studentId, let weekId, let weekTitle):
                        guardedHome {
                            StudentWeekDetailView(
                                path: $path,
                                studentId: studentId,
                                weekId: weekId,
                                weekTitle: weekTitle
                            )
                        }

                    case .studentDayDetail(let weekId, let day, let weekTitle):
                        guardedHome {
                            StudentDayDetailView(
                                path: $path,
                                weekId: weekId,
                                day: day,
                                weekTitle: weekTitle
                            )
                        }

                    case .studentMessages(let category):
                        guardedStudent {
                            StudentMessagesView(
                                path: $path,
                                category: category
                            )
                        }

                    case .studentFeedbacks(let category):
                        guardedStudent {
                            StudentFeedbacksView(
                                path: $path,
                                category: category
                            )
                        }

                    // ✅ NOVO: Recorde Pessoal (Aluno)
                    case .studentPersonalRecords:
                        guardedStudent {
                            StudentPersonalRecordsView(path: $path)
                        }

                    // ✅ NOVO: Barbell (Recorde Pessoal > Barbell)
                    case .studentPersonalRecordsBarbell:
                        guardedStudent {
                            StudentBarbellPersonalRecordsView(path: $path)
                        }

                    case .sobre:
                        guardedHome { AboutView(path: $path) }

                    case .perfil:
                        guardedHome { ProfileView(path: $path) }

                    case .treinos(let tipo):
                        guardedHome { TreinosView(path: $path, tipo: tipo) }

                    case .crossfitMenu:
                        guardedHome { CrossfitMenuView(path: $path) }

                    case .configuracoes:
                        guardedHome { SettingsView(path: $path) }

                    case .infoLegal(let kind):
                        guardedHome { InfoLegalView(path: $path, kind: kind) }

                    case .editarPerfil:
                        guardedHome { EditProfileView(path: $path) }

                    case .alterarSenha:
                        guardedHome { ChangePasswordView(path: $path) }

                    case .excluirConta:
                        guardedHome { DeleteAccountView(path: $path) }

                    case .spriteDemo:
                        guardedHome { SpriteDemoView(path: $path) }

                    case .arExercise(let weekId, let dayId):
                        guardedHome { ARExerciseView(path: $path, weekId: weekId, dayId: dayId) }

                    case .accountTypeSelection:
                        AccountTypeSelectionView(path: $path)
                            .environmentObject(session)

                    case .registerStudent:
                        RegisterStudentView(path: $path)
                            .environmentObject(session)

                    case .registerTrainer:
                        RegisterTrainerView(path: $path)
                            .environmentObject(session)

                    case .teacherMyWorkouts(let category):
                        guardedTeacher {
                            TeacherMyWorkoutsView(path: $path, category: category)
                        }

                    case .teacherCrossfitLibrary(let section):
                        guardedTeacher {
                            TeacherCrossfitLibraryView(path: $path, section: section)
                        }

                    case .teacherWorkoutTemplates(let category, let sectionKey, let sectionTitle):
                        guardedTeacher {
                            TeacherWorkoutTemplatesView(
                                path: $path,
                                category: category,
                                sectionKey: sectionKey,
                                sectionTitle: sectionTitle
                            )
                        }

                    case .teacherImportWorkouts(let category):
                        guardedTeacher {
                            TeacherImportWorkoutsView(
                                path: $path,
                                category: category
                            )
                        }

                    case .teacherImportVideos(let category):
                        guardedTeacher {
                            TeacherImportVideosView(
                                path: $path,
                                category: category
                            )
                        }

                    case .createCrossfitWOD(let category, let sectionKey, let sectionTitle):
                        guardedTeacher {
                            CreateCrossfitWODView(
                                path: $path,
                                category: category,
                                sectionKey: sectionKey,
                                sectionTitle: sectionTitle
                            )
                        }

                    case .createTreinoAcademia(let category, let sectionKey, let sectionTitle):
                        guardedTeacher {
                            CreateTreinoAcademiaView(
                                path: $path,
                                category: category,
                                sectionKey: sectionKey,
                                sectionTitle: sectionTitle
                            )
                        }

                    case .createTreinoCasa(let category, let sectionKey, let sectionTitle):
                        guardedTeacher {
                            CreateTreinoCasaView(
                                path: $path,
                                category: category,
                                sectionKey: sectionKey,
                                sectionTitle: sectionTitle
                            )
                        }

                    default:
                        guardedHome()
                    }
                }
        }
        .environmentObject(session)
        .onChange(of: session.isLoggedIn) { _, logged in
            if !logged { path.removeAll() }
        }
    }
}

// Métodos auxiliares para decidir a view raiz e aplicar guards de autenticação
private extension AppRouter {

    var teacherInitialCategory: TreinoTipo {
        let raw = UserDefaults.standard.string(forKey: ultimoTreinoKey) ?? TreinoTipo.crossfit.rawValue
        return TreinoTipo(rawValue: raw) ?? .crossfit
    }

    @ViewBuilder
    var rootView: some View {
        if session.isLoggedIn {

            if session.isTrainer {
                TeacherDashboardView(path: $path, category: teacherInitialCategory)
            } else {
                StudentAgendaView(
                    path: $path,
                    studentId: session.uid ?? "",
                    studentName: session.userName ?? ""
                )
            }

        } else {
            LoginView(path: $path)
        }
    }
}

// Métodos de proteção para garantir que usuários estejam autenticados e autorizados
private extension AppRouter {

    @ViewBuilder
    func guardedHome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn { content() } else { LoginView(path: $path) }
    }

    @ViewBuilder
    func guardedHome() -> some View {
        if session.isLoggedIn {
            if session.isTrainer {
                TeacherDashboardView(path: $path, category: teacherInitialCategory)
            } else {
                HomeView(path: $path)
            }
        } else {
            LoginView(path: $path)
        }
    }

    @ViewBuilder
    func guardedTeacher<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isTrainer { content() } else { LoginView(path: $path) }
    }

    @ViewBuilder
    func guardedStudent<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isStudent { content() } else { LoginView(path: $path) }
    }
}

