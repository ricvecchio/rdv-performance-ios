import SwiftUI

// MARK: - APP CONTAINER / NAVIGATION
struct AppRouter: View {

    @State private var path: [AppRoute] = []
    @StateObject private var session = AppSession()

    var body: some View {
        NavigationStack(path: $path) {

            LoginView(path: $path)
                .environmentObject(session)

                .navigationDestination(for: AppRoute.self) { route in
                    switch route {

                    case .login:
                        LoginView(path: $path)
                            .environmentObject(session)

                    // ===== PROFESSOR =====
                    case .home:
                        HomeView(path: $path)

                    case .teacherStudentsList(let tipo):
                        TeacherStudentsListView(path: $path, selectedCategory: tipo)
                            .environmentObject(session)

                    case .teacherStudentDetail(let student, let category):
                        TeacherStudentDetailView(
                            path: $path,
                            student: student,
                            category: category
                        )
                        .environmentObject(session)

                    // ===== ALUNO =====
                    case .studentAgenda(let studentId, let studentName):
                        StudentAgendaView(
                            path: $path,
                            studentId: studentId,
                            studentName: studentName
                        )

                    case .studentWeekDetail(let studentId, let weekId, let weekTitle):
                        StudentWeekDetailView(
                            path: $path,
                            studentId: studentId,
                            weekId: weekId,
                            weekTitle: weekTitle
                        )

                    // ===== PUBLICAR TREINOS (PROFESSOR) =====
                    case .createTrainingWeek(let category):
                        Text("Criar Semana - \(category.rawValue)")
                            .environmentObject(session)

                    case .createTrainingDay(let weekId, let category):
                        Text("Criar Dia - weekId: \(weekId) | \(category.rawValue)")
                            .environmentObject(session)

                    // ===== COMUM =====
                    case .sobre:
                        AboutView(path: $path)

                    case .perfil:
                        ProfileView(path: $path)

                    case .treinos(let tipo):
                        TreinosView(path: $path, tipo: tipo)

                    case .crossfitMenu:
                        CrossfitMenuView(path: $path)

                    case .configuracoes:
                        SettingsView(path: $path)

                    // ===== CADASTRO =====
                    case .accountTypeSelection:
                        AccountTypeSelectionView(path: $path)

                    case .registerStudent:
                        RegisterStudentView(path: $path)

                    case .registerTrainer:
                        RegisterTrainerView(path: $path)
                    }
                }
        }
        .environmentObject(session)
    }
}

