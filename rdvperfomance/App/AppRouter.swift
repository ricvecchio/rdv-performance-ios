import SwiftUI

// MARK: - APP CONTAINER / NAVIGATION
struct AppRouter: View {

    @State private var path: [AppRoute] = []
    @StateObject private var session = AppSession()

    var body: some View {
        NavigationStack(path: $path) {

            rootView
                .environmentObject(session)

                .navigationDestination(for: AppRoute.self) { route in
                    switch route {

                    // ===== BASE =====
                    case .login:
                        LoginView(path: $path)
                            .environmentObject(session)

                    case .home:
                        guardedHome()

                    // ===== PROFESSOR =====
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

                    // ===== PUBLICAR TREINOS (PROFESSOR) =====
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

                    // ===== ALUNO + PROFESSOR (COMPARTILHADO) =====
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

                    // ===== ALUNO =====
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

                    // ===== COMUM (LOGIN OBRIGATÓRIO) =====
                    case .sobre:
                        guardedHome {
                            AboutView(path: $path)
                        }

                    case .perfil:
                        guardedHome {
                            ProfileView(path: $path)
                        }

                    case .treinos(let tipo):
                        guardedHome {
                            TreinosView(path: $path, tipo: tipo)
                        }

                    case .crossfitMenu:
                        guardedHome {
                            CrossfitMenuView(path: $path)
                        }

                    case .configuracoes:
                        guardedHome {
                            SettingsView(path: $path)
                        }

                    case .infoLegal(let kind):
                        guardedHome {
                            InfoLegalView(path: $path, kind: kind)
                        }

                    case .editarPerfil:
                        guardedHome {
                            EditProfileView(path: $path)
                        }

                    case .alterarSenha:
                        guardedHome {
                            ChangePasswordView(path: $path)
                        }

                    case .excluirConta:
                        guardedHome {
                            DeleteAccountView(path: $path)
                        }

                    // ===== DEVELOPER / DEMOS (via Settings) =====
                    case .mapFeature:
                        guardedHome {
                            MapFeatureView()
                        }

                    case .spriteDemo:
                        guardedHome {
                            // ✅ agora segue padrão (header/avatar/footer) porque recebe path
                            SpriteDemoView(path: $path)
                        }

                    case .arDemo:
                        guardedHome {
                            ARDemoView()
                        }

                    case .arExercise(let weekId, let dayId):
                        guardedHome {
                            ARExerciseView(path: $path, weekId: weekId, dayId: dayId)
                        }

                    // ===== CADASTRO (SEM LOGIN) =====
                    case .accountTypeSelection:
                        AccountTypeSelectionView(path: $path)
                            .environmentObject(session)

                    case .registerStudent:
                        RegisterStudentView(path: $path)
                            .environmentObject(session)

                    case .registerTrainer:
                        RegisterTrainerView(path: $path)
                            .environmentObject(session)

                    // ✅ Boa prática: evita “Switch must be exhaustive” se AppRoute ganhar novos cases
                    @unknown default:
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

// MARK: - Root decision
private extension AppRouter {

    @ViewBuilder
    var rootView: some View {
        if session.isLoggedIn {
            HomeView(path: $path)
        } else {
            LoginView(path: $path)
        }
    }
}

// MARK: - Guards
private extension AppRouter {

    @ViewBuilder
    func guardedHome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn {
            content()
        } else {
            LoginView(path: $path)
        }
    }

    @ViewBuilder
    func guardedHome() -> some View {
        if session.isLoggedIn {
            HomeView(path: $path)
        } else {
            LoginView(path: $path)
        }
    }

    @ViewBuilder
    func guardedTeacher<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isTrainer {
            content()
        } else {
            LoginView(path: $path)
        }
    }

    @ViewBuilder
    func guardedStudent<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isStudent {
            content()
        } else {
            LoginView(path: $path)
        }
    }
}

