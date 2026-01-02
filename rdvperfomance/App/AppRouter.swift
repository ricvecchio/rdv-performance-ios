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

                    case .login:
                        LoginView(path: $path)
                            .environmentObject(session)

                    case .home:
                        guardedHome()
                            .environmentObject(session)

                    // ===== PROFESSOR =====
                    case .teacherStudentsList(let tipo):
                        guardedTeacher {
                            TeacherStudentsListView(path: $path, selectedCategory: tipo)
                                .environmentObject(session)
                        }

                    case .teacherStudentDetail(let student, let category):
                        guardedTeacher {
                            TeacherStudentDetailView(
                                path: $path,
                                student: student,
                                category: category
                            )
                            .environmentObject(session)
                        }

                    case .teacherDashboard(let category):
                        guardedTeacher {
                            TeacherDashboardView(path: $path, category: category)
                                .environmentObject(session)
                        }

                    case .teacherLinkStudent(let category):
                        guardedTeacher {
                            TeacherLinkStudentView(path: $path, category: category)
                                .environmentObject(session)
                        }

                    // ===== ALUNO =====
                    // ✅ Ajuste: professor também pode ver (modo leitura)
                    case .studentAgenda(let studentId, let studentName):
                        guardedHome() {
                            StudentAgendaView(
                                path: $path,
                                studentId: studentId,
                                studentName: studentName
                            )
                            .environmentObject(session)
                        }

                    // ✅ Ajuste: professor também pode ver (modo leitura)
                    case .studentWeekDetail(let studentId, let weekId, let weekTitle):
                        guardedHome() {
                            StudentWeekDetailView(
                                path: $path,
                                studentId: studentId,
                                weekId: weekId,
                                weekTitle: weekTitle
                            )
                            .environmentObject(session)
                        }

                    // ✅ Ajuste: professor também pode ver (modo leitura)
                    case .studentDayDetail(let day, let weekTitle):
                        guardedHome() {
                            StudentDayDetailView(path: $path, day: day, weekTitle: weekTitle)
                                .environmentObject(session)
                        }

                    // ===== PUBLICAR TREINOS (PROFESSOR) =====
                    case .createTrainingWeek(let student, let category):
                        guardedTeacher {
                            CreateTrainingWeekView(path: $path, student: student, category: category)
                                .environmentObject(session)
                        }

                    case .createTrainingDay(let weekId, let category):
                        guardedTeacher {
                            CreateTrainingDayView(path: $path, weekId: weekId, category: category)
                                .environmentObject(session)
                        }

                    // ===== COMUM =====
                    case .sobre:
                        AboutView(path: $path)
                            .environmentObject(session)

                    case .perfil:
                        ProfileView(path: $path)
                            .environmentObject(session)

                    case .treinos(let tipo):
                        TreinosView(path: $path, tipo: tipo)
                            .environmentObject(session)

                    case .crossfitMenu:
                        CrossfitMenuView(path: $path)
                            .environmentObject(session)

                    case .configuracoes:
                        SettingsView(path: $path)
                            .environmentObject(session)

                    // ===== CADASTRO =====
                    case .accountTypeSelection:
                        AccountTypeSelectionView(path: $path)
                            .environmentObject(session)

                    case .registerStudent:
                        RegisterStudentView(path: $path)
                            .environmentObject(session)

                    case .registerTrainer:
                        RegisterTrainerView(path: $path)
                            .environmentObject(session)
                    }
                }
        }
        .environmentObject(session)
        .onChange(of: session.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn { path.removeAll() }
        }
    }
}

// MARK: - Root decision
private extension AppRouter {

    @ViewBuilder
    var rootView: some View {
        if session.isLoggedIn {
            HomeView(path: $path)
                .environmentObject(session)
        } else {
            LoginView(path: $path)
                .environmentObject(session)
        }
    }
}

// MARK: - Guards
private extension AppRouter {

    @ViewBuilder
    func guardedHome() -> some View {
        if session.isLoggedIn {
            HomeView(path: $path)
                .environmentObject(session)
        } else {
            LoginView(path: $path)
                .environmentObject(session)
        }
    }

    // ✅ overload: permite usar guardedHome { ... }
    @ViewBuilder
    func guardedHome<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn {
            content()
        } else {
            LoginView(path: $path)
                .environmentObject(session)
        }
    }

    @ViewBuilder
    func guardedTeacher<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isTrainer {
            content()
        } else {
            LoginView(path: $path)
                .environmentObject(session)
        }
    }

    @ViewBuilder
    func guardedStudent<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isStudent {
            content()
        } else {
            LoginView(path: $path)
                .environmentObject(session)
        }
    }
}

