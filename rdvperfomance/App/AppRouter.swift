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
                            .environmentObject(session) // ✅ garante session

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

                    case .teacherDashboard(let category):
                        TeacherDashboardView(path: $path, category: category)
                            .environmentObject(session)

                    // ===== ALUNO =====
                    case .studentAgenda(let studentId, let studentName):
                        StudentAgendaView(
                            path: $path,
                            studentId: studentId,
                            studentName: studentName
                        )
                        .environmentObject(session)

                    case .studentWeekDetail(let studentId, let weekId, let weekTitle):
                        StudentWeekDetailView(
                            path: $path,
                            studentId: studentId,
                            weekId: weekId,
                            weekTitle: weekTitle
                        )
                        .environmentObject(session)

                    // ===== PUBLICAR TREINOS (PROFESSOR) =====
                    case .createTrainingWeek(let category):
                        CreateTrainingWeekView(path: $path, category: category)
                            .environmentObject(session)

                    case .createTrainingDay(let weekId, let category):
                        // Ainda placeholder (quando você criar a tela, substitui aqui)
                        Text("Criar Dia - weekId: \(weekId) | \(category.rawValue)")
                            .foregroundColor(.white)
                            .environmentObject(session)

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
    }
}

