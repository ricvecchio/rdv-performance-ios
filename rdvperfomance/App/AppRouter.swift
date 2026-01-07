// AppRouter.swift — Componente responsável pela navegação e roteamento do app
import SwiftUI

// Container principal de navegação
struct AppRouter: View {

    // Estado local de rotas e sessão
    @State private var path: [AppRoute] = []
    @EnvironmentObject private var session: AppSession

    // Corpo com NavigationStack e destinos de navegação
    var body: some View {
        NavigationStack(path: $path) {

            rootView

                .navigationDestination(for: AppRoute.self) { route in
                    switch route {

                    // BASE
                    case .login:
                        LoginView(path: $path)

                    case .home:
                        guardedHome()

                    // PROFESSOR (exclusivo)
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

                    // ALUNO + PROFESSOR (COMPARTILHADO)
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

                    // ALUNO (exclusivo)
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

                    // COMUM (login obrigatório)
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

                    // Demo / Developer (acesso via Settings)
                    case .mapFeature:
                        guardedHome {
                            MapFeatureView()
                        }

                    case .spriteDemo:
                        guardedHome {
                            SpriteDemoView()
                        }

                    case .arDemo:
                        guardedHome {
                            ARDemoView()
                        }

                    // CADASTRO (sem login)
                    case .accountTypeSelection:
                        AccountTypeSelectionView(path: $path)

                    case .registerStudent:
                        RegisterStudentView(path: $path)

                    case .registerTrainer:
                        RegisterTrainerView(path: $path)
                    }
                }
        }
        .onChange(of: session.isLoggedIn) { _, logged in
            if !logged { path.removeAll() }
        }
    }
}

// Root decision: escolhe tela inicial baseada no estado de sessão
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

// Guards: funções auxiliares para proteger rotas por tipo de usuário
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
