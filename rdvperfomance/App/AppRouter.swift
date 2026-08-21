import SwiftUI

// Container principal de navegação do aplicativo
struct AppRouter: View {

    @State private var path: [AppRoute] = []
    @StateObject private var session = AppSession()
    @State private var popGestureInstaller = NavigationPopGestureInstaller()

    private let ultimoTreinoKey: String = "ultimoTreinoSelecionado"


    var body: some View {
        Group {

            // ✅ ALUNO: navegação totalmente independente do NavigationStack
            // abaixo. `StudentRootView` é dona da sua própria seleção de
            // seção principal (Agenda/Recordes/Perfil) e de 3 pilhas de
            // navegação hierárquica isoladas. Isso evita ter um
            // NavigationStack dentro de outro sem necessidade e elimina a
            // causa raiz do bug de navegação relatado (footer competindo com
            // push/pop no mesmo `path`). A arquitetura do professor abaixo
            // permanece inalterada.
            if session.isLoggedIn && session.isStudent {
                StudentRootView(
                    studentId: session.uid ?? "",
                    studentName: session.userName ?? ""
                )
                .environmentObject(session)
            } else {
                NavigationStack(path: $path) {

                    rootView
                        .environmentObject(session)
                        .background(
                            NavigationPopGestureFixer(
                                installer: popGestureInstaller,
                                stackDepth: path.count
                            )
                        )

                        .navigationDestination(for: AppRoute.self) { route in
                            Group {
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

                    case .studentPersonalRecords, .studentPersonalRecordsBarbell, .studentPersonalRecordsGymnastic,
                         .studentPersonalRecordsEndurance, .studentPersonalRecordsNotables, .studentPersonalRecordsGirls,
                         .studentPersonalRecordsOpen, .studentPersonalRecordsHeroes, .studentPersonalRecordsCampeonatos,
                         .studentPersonalRecordsCrossfitGames, .studentMessages, .studentFeedbacks:
                        // ✅ Rotas exclusivas da seção "Recordes"/"Perfil" do próprio aluno.
                        // Desde a introdução de `StudentRootView`, o aluno nunca navega
                        // através deste NavigationStack (ele é interceptado mais acima,
                        // antes deste `NavigationStack` sequer existir) — por isso essas
                        // rotas nunca são empurradas aqui. Mantidas apenas como fallback
                        // seguro (nunca deveriam ser alcançadas nesta pilha).
                        guardedHome()

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

                    // ✅ NOVO: menus para Academia e Em Casa (blocos por músculo)
                    case .teacherAcademiaLibrary:
                        guardedTeacher {
                            TeacherAcademiaLibraryView(path: $path)
                        }

                    case .teacherEmCasaLibrary:
                        guardedTeacher {
                            TeacherEmCasaLibraryView(path: $path)
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
            }
        } // fecha else (fluxo professor / não-aluno)
        } // fecha Group (aluno vs. professor)
        .environmentObject(session)
        .onChange(of: session.isLoggedIn) { _, logged in
            guard !logged else { return }

            #if DEBUG
            print("[AppRouter] Session logout. Clearing path:", String(describing: path))
            #endif

            path.removeAll()
        }
        .onChange(of: path) { oldPath, newPath in
            #if DEBUG
            print("[AppRouter] Path changed from:", String(describing: oldPath))
            print("[AppRouter] Path changed to:", String(describing: newPath))
            #endif
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
    func guardedStudent<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if session.isLoggedIn && session.isStudent { content() } else { LoginView(path: $path) }
    }
}
