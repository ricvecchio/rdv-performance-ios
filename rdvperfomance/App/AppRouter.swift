import SwiftUI

// Container principal de navegação do aplicativo
struct AppRouter: View {

    @State private var path: [AppRoute] = []
    @StateObject private var session = AppSession()

    private let ultimoTreinoKey: String = "ultimoTreinoSelecionado"

    @State private var showPlanExpiredAlert: Bool = false

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
                        guardedTeacherPro {
                            CreateTrainingWeekView(
                                path: $path,
                                student: student,
                                category: category
                            )
                        }

                    case .createTrainingDay(let weekId, let category):
                        guardedTeacherPro {
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

                    case .studentPersonalRecords:
                        guardedStudent {
                            StudentPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsBarbell:
                        guardedStudent {
                            StudentBarbellPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsGymnastic:
                        guardedStudent {
                            StudentGymnasticPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsEndurance:
                        guardedStudent {
                            StudentEndurancePersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsNotables:
                        guardedStudent {
                            StudentNotablesPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsGirls:
                        guardedStudent {
                            StudentGirlsPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsOpen:
                        guardedStudent {
                            StudentOpenPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsHeroes:
                        guardedStudent {
                            StudentHeroesPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsCampeonatos:
                        guardedStudent {
                            StudentCampeonatosPersonalRecordsView(path: $path)
                        }

                    case .studentPersonalRecordsCrossfitGames:
                        guardedStudent {
                            StudentCrossfitGamesPersonalRecordsView(path: $path)
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
                        guardedTeacherPro {
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
                        guardedTeacherPro {
                            CreateCrossfitWODView(
                                path: $path,
                                category: category,
                                sectionKey: sectionKey,
                                sectionTitle: sectionTitle
                            )
                        }

                    case .createTreinoAcademia(let category, let sectionKey, let sectionTitle):
                        guardedTeacherPro {
                            CreateTreinoAcademiaView(
                                path: $path,
                                category: category,
                                sectionKey: sectionKey,
                                sectionTitle: sectionTitle
                            )
                        }

                    case .createTreinoCasa(let category, let sectionKey, let sectionTitle):
                        guardedTeacherPro {
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
        .alert("Plano expirado", isPresented: $showPlanExpiredAlert) {
            Button("Agora não", role: .cancel) {
                popDeniedRoute()
            }

            Button("Renovar/Contratar") {
                popDeniedRoute()
                openPlanUpgradeFromAnywhere()
            }
        } message: {
            Text("Plano expirado, deseja renovar/contratar?")
        }
    }
}

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
    func guardedTeacherPro<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isTrainer {
            if session.canUseTrainerProFeatures {
                content()
            } else {
                planExpiredUpgradeView()
            }
        } else {
            LoginView(path: $path)
        }
    }

    @ViewBuilder
    func guardedStudent<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isStudent { content() } else { LoginView(path: $path) }
    }

    func popDeniedRoute() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func openPlanUpgradeFromAnywhere() {
        if path.last != .perfil {
            path.append(.perfil)
        }
        session.shouldPresentPlanModal = true
    }

    func planExpiredUpgradeView() -> some View {
        let contentMaxWidth: CGFloat = 380

        return ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            Text("Seu plano expirou.")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))
                                .padding(.top, 12)

                            Text("Para adicionar novos WODs e continuar criando/enviando treinos, renove/contrate o Plano Pro.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.55))

                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.green.opacity(0.85))

                                    Text("Plano Pro")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))

                                    Spacer()

                                    Text("Expirado")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.red.opacity(0.95))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.red.opacity(0.18)))
                                }

                                Text("Toque em “Renovar/Contratar” para abrir o modal de Planos no Perfil.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            .padding(14)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )

                            Button {
                                popDeniedRoute()
                                openPlanUpgradeFromAnywhere()
                            } label: {
                                HStack(spacing: 10) {
                                    Text("Renovar/Contratar")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.35))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.green.opacity(0.20))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)

                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        Spacer(minLength: 0)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Planos")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fechar") {
                    popDeniedRoute()
                }
                .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
