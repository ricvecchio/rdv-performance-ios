import SwiftUI

/// Raiz de navegação do ALUNO.
///
/// Esta view é o coração da correção arquitetural: ela é a ÚNICA dona da
/// "seção principal" selecionada (Treinos / Recordes / Perfil) e de TRÊS
/// pilhas de navegação hierárquica totalmente independentes — uma por seção.
///
/// Por quê:
/// Antes desta refatoração, o Footer do aluno mutava o MESMO `path` usado
/// pelo `NavigationStack` global (`path = []`, `path = [.studentPersonalRecords]`,
/// `path = [.perfil]`). Ou seja, trocar de aba no rodapé era tratado como
/// push/pop de navegação hierárquica. Isso criava condições de corrida reais
/// entre: (1) o toque no rodapé mutando `path`, (2) uma transição de
/// push/pop do UIKit ainda em andamento, e (3) o gesto de swipe-back
/// (`interactivePopGestureRecognizer`) competindo pelo mesmo estado. O
/// resultado observável era exatamente o reportado: troca de aba atrasada,
/// necessidade de tocar duas vezes, e o botão `<` de Recordes não fazendo
/// nada (porque `path.removeLast()` era um no-op quando `path` já estava
/// vazio — Recordes SEMPRE chegava com `path = [.studentPersonalRecords]`,
/// ou seja, `path.count == 1`; ao dar pop, o "topo" virava a raiz do
/// NavigationStack, mas nada de fato pedia para trocar para Treinos).
///
/// Como ficou:
/// - `selectedSection` é só um enum (`StudentMainSection`), trocado por uma
///   simples atribuição de estado — nunca um push/pop.
/// - `workoutsPath` / `recordsPath` / `profilePath` são 3 arrays de `AppRoute`
///   independentes, cada um dono de um `NavigationStack` próprio. Cada um
///   representa SOMENTE os filhos hierárquicos daquela seção (ex.:
///   `recordsPath = [.studentPersonalRecordsBarbell]`, nunca
///   `[.studentPersonalRecords, .studentPersonalRecordsBarbell]` — a própria
///   seção nunca aparece dentro do seu próprio path).
/// - Somente a seção selecionada é montada. Assim, a largura intrínseca de
///   uma aba inativa não pode alterar o viewport da tela visível.
/// - O botão `<` da raiz de Recordes e da raiz de Perfil deixou de ser um
///   pop (que já não fazia sentido, pois essas telas são a RAIZ da sua
///   própria pilha) e passou a significar exatamente o que o produto exige:
///   "voltar para Treinos" == `selectedSection = .agenda`.
struct StudentRootView: View {

    @EnvironmentObject private var session: AppSession
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale

    let studentId: String
    let studentName: String

    @State private var selectedSection: StudentMainSection = .home

    @State private var homePath: [AppRoute] = []
    @State private var workoutsPath: [AppRoute] = []
    @State private var remindersPath: [StudentRemindersRoute] = []
    @State private var recordsPath: [AppRoute] = []
    @State private var profilePath: [AppRoute] = []
    @State private var menuPath: [AppRoute] = []
    /// Seção (Anotações/Lembretes/Aniversários) a abrir diretamente ao entrar em Lembretes pelo Menu.
    @State private var remindersInitialSection: PersonalOrganizerSection = .notes
    @State private var workoutsInitialWeekId: String?
    @State private var workoutsInitialDayId: String?

    /// Mantém o cache de Treinos da Semana entre trocas de aba (somente a aba
    /// selecionada é montada, o que recriaria o ViewModel a cada retorno).
    @StateObject private var workoutsViewModel: StudentWorkoutsViewModel

    /// Disponibilidade da aba Treinos (vínculo com professor), compartilhada com o rodapé.
    @StateObject private var tabsState = StudentTabsState()

    /// Anotações, lembretes e aniversários pessoais (isolados por UID) e suas notificações locais.
    @StateObject private var organizerStore = PersonalOrganizerStore()

    init(studentId: String, studentName: String) {
        self.studentId = studentId
        self.studentName = studentName
        _workoutsViewModel = StateObject(
            wrappedValue: StudentWorkoutsViewModel(studentId: studentId, repository: .shared)
        )
    }

    var body: some View {
        tabContentWithObservers
            .onChange(of: scenePhase) { _, phase in
                handleScenePhase(phase)
            }
            .onChange(of: locale) { _, _ in
                organizerStore.reconcileNotifications()
            }
    }

    /// Conteúdo da aba selecionada com ambiente compartilhado e atualização do rodapé.
    private var tabContentWithObservers: some View {
        selectedTab
            .environment(\.selectStudentMainSection, selectSection)
            .environment(\.studentShowsWorkoutsTab, tabsState.showsWorkouts)
            .environmentObject(organizerStore)
            .task(id: studentId) {
                organizerStore.start(ownerUid: studentId)
                await tabsState.refresh(studentId: studentId)
            }
            // Vínculo/desvínculo (Home, Perfil > Professores): atualiza o rodapé sem novo login
            .onChange(of: selectedSection) { _, section in
                handleSectionChange(section)
            }
            .onChange(of: homePath) { _, _ in
                refreshTabs()
            }
            .onChange(of: profilePath) { _, _ in
                refreshTabs()
            }
            .onChange(of: tabsState.teacherLinkState) { _, state in
                handleTeacherLinkChange(state)
            }
    }

    private func refreshTabs() {
        Task { await tabsState.refresh(studentId: studentId) }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        refreshTabs()
        organizerStore.retryIfNeeded()
        Task {
            await organizerStore.refreshAuthorization()
            organizerStore.reconcileNotifications()
        }
    }

    private func handleSectionChange(_ section: StudentMainSection) {
        if section == .reminders { organizerStore.retryIfNeeded() }
        refreshTabs()
    }

    /// Perdeu o último vínculo enquanto estava em Treinos: volta à Home sem pilha residual.
    private func handleTeacherLinkChange(_ state: StudentDashboardTeacherLinkState) {
        guard state == .unlinked, selectedSection == .agenda else { return }
        workoutsPath = []
        homePath = []
        selectedSection = .home
    }

    @ViewBuilder
    private var selectedTab: some View {
        switch selectedSection {
        case .home:
            homeTab
        case .agenda:
            workoutsTab
        case .reminders:
            remindersTab
        case .records:
            recordsTab
        case .profile:
            profileTab
        case .menu:
            menuTab
        }
    }

    // MARK: - Seleção de seção (chamada pelo FooterBar de qualquer tela do aluno)

    /// Troca a seção principal. Se a seção de destino já estiver selecionada
    /// E já estiver na sua raiz, não faz nada (idempotente). Caso contrário,
    /// a pilha local da seção de destino é resetada para a raiz — conforme
    /// decisão de produto: "ao selecionar um ícone do rodapé, abrir a raiz
    /// daquela seção" (não é necessário preservar profundidade entre trocas
    /// de aba).
    private func selectSection(_ requested: StudentMainSection) {
        // Sem professor confirmado a aba Treinos não existe: redireciona para a Home
        let target: StudentMainSection =
            (requested == .agenda && !tabsState.showsWorkouts) ? .home : requested

        let alreadyAtRoot: Bool
        switch target {
        case .home: alreadyAtRoot = homePath.isEmpty
        case .agenda: alreadyAtRoot = workoutsPath.isEmpty
        case .reminders: alreadyAtRoot = remindersPath.isEmpty
        case .records: alreadyAtRoot = recordsPath.isEmpty
        case .profile: alreadyAtRoot = profilePath.isEmpty
        case .menu: alreadyAtRoot = menuPath.isEmpty
        }

        if selectedSection == target && alreadyAtRoot { return }

        switch target {
        case .home: homePath = []
        case .agenda: workoutsPath = []
        case .reminders: remindersPath = []
        case .records: recordsPath = []
        case .profile: profilePath = []
        case .menu: menuPath = []
        }

        selectedSection = target
    }

    /// Abre Anotações, Lembretes ou Aniversários diretamente (sem passar por outra tela).
    private func openOrganizer(_ organizerSection: PersonalOrganizerSection) {
        remindersPath = []
        remindersInitialSection = organizerSection
        selectedSection = .reminders
    }

    private func openWorkouts(weekId: String, dayId: String) {
        workoutsPath = []
        workoutsInitialWeekId = weekId
        workoutsInitialDayId = dayId
        selectedSection = .agenda
    }

    // MARK: - Treinos

    private var homeTab: some View {
        NavigationStack(path: $homePath) {
            StudentDashboardView(
                path: $homePath,
                studentId: studentId,
                onSelectSection: selectSection,
                onSelectWorkout: openWorkouts
            )
            .navigationDestination(for: AppRoute.self) { route in
                workoutsDestination(for: route, path: $homePath)
            }
        }
    }

    private var workoutsTab: some View {
        NavigationStack(path: $workoutsPath) {
            TrainingWeeksView(
                path: $workoutsPath,
                studentId: studentId,
                studentName: studentName,
                initialExpandedWeekId: workoutsInitialWeekId,
                initialExpandedDayId: workoutsInitialDayId,
                onInitialExpansionHandled: {
                    workoutsInitialWeekId = nil
                    workoutsInitialDayId = nil
                },
                onSelectSection: selectSection,
                viewModel: workoutsViewModel
            )
            .navigationDestination(for: AppRoute.self) { route in
                workoutsDestination(for: route, path: $workoutsPath)
            }
        }
    }

    @ViewBuilder
    private func workoutsDestination(for route: AppRoute, path: Binding<[AppRoute]>) -> some View {
        switch route {

        case .studentDayDetail(let weekId, let day, let weekTitle):
            TrainingDayDetailView(
                path: path,
                weekId: weekId,
                day: day,
                weekTitle: weekTitle,
                onSelectSection: selectSection
            )


        case .studentTeachers(let studentEmail):
            StudentTeachersView(
                path: path,
                studentEmail: studentEmail,
                onSelectSection: selectSection
            )

        case .studentNextFitWod:
            StudentNextFitWodView(
                path: path,
                studentId: studentId,
                onSelectSection: selectSection
            )

        // Aberta pelo aviso de novidade de temas (1.0.25) na Home do aluno
        case .tema:
            ThemeSettingsView()

        default:
            EmptyView()
        }
    }

    // MARK: - Lembretes

    private var remindersTab: some View {
        NavigationStack(path: $remindersPath) {
            StudentRemindersView(
                path: $remindersPath,
                onBack: { selectSection(.menu) },
                onSelectSection: selectSection,
                initialSection: remindersInitialSection
            )
            .navigationDestination(for: StudentRemindersRoute.self) { route in
                switch route {
                case .birthdays:
                    StudentBirthdaysView(path: $remindersPath, onSelectSection: selectSection)
                }
            }
        }
    }

    // MARK: - Recordes

    private var recordsTab: some View {
        NavigationStack(path: $recordsPath) {
            PersonalRecordsView(
                path: $recordsPath,
                onBack: { selectSection(.menu) },
                onSelectSection: selectSection
            )
            .navigationDestination(for: AppRoute.self) { route in
                recordsDestination(for: route)
            }
        }
    }

    @ViewBuilder
    private func recordsDestination(for route: AppRoute) -> some View {
        switch route {

        case .studentPersonalRecordsBarbell:
            BarbellPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsGymnastic:
            GymnasticPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsEndurance:
            EndurancePersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsNotables:
            NotablesPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsGirls:
            GirlsPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsOpen:
            OpenPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsHeroes:
            HeroesPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsCampeonatos:
            CampeonatosPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentPersonalRecordsCrossfitGames:
            CrossfitGamesPersonalRecordsView(path: $recordsPath, onSelectSection: selectSection)

        case .studentVideos:
            YoutubeVideosView(
                path: $recordsPath,
                context: .student(studentId: studentId)
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Menu

    private var menuTab: some View {
        NavigationStack(path: $menuPath) {
            StudentMenuView(
                path: $menuPath,
                onBack: { selectSection(.home) },
                onSelectSection: selectSection,
                onOpenOrganizer: openOrganizer
            )
            .navigationDestination(for: AppRoute.self) { route in
                menuDestination(for: route)
            }
        }
    }

    /// Destinos empilhados a partir do Menu (reutiliza as telas existentes de WOD, Configurações e Ajuda).
    @ViewBuilder
    private func menuDestination(for route: AppRoute) -> some View {
        switch route {

        case .studentNextFitWod:
            StudentNextFitWodView(
                path: $menuPath,
                studentId: studentId,
                onSelectSection: selectSection
            )

        case .studentComingSoon(let titleKey):
            StudentComingSoonView(
                path: $menuPath,
                titleKey: titleKey,
                onSelectSection: selectSection
            )

        default:
            profileDestination(for: route, path: $menuPath)
        }
    }

    // MARK: - Perfil

    private var profileTab: some View {
        NavigationStack(path: $profilePath) {
            ProfileView(
                path: $profilePath,
                onBack: { selectSection(.home) }
            )
            .navigationDestination(for: AppRoute.self) { route in
                profileDestination(for: route, path: $profilePath)
            }
        }
    }

    @ViewBuilder
    private func profileDestination(for route: AppRoute, path: Binding<[AppRoute]>) -> some View {
        switch route {

        case .configuracoes:
            SettingsView(path: path)

        case .idioma:
            LanguageSettingsView()

        case .tema:
            ThemeSettingsView()

        case .editarPerfil:
            EditProfileView(path: path)

        case .alterarSenha:
            ChangePasswordView(path: path)

        case .excluirConta:
            DeleteAccountView(path: path)

        case .infoLegal(let kind):
            InfoLegalView(path: path, kind: kind, onSelectSection: selectSection)

        case .sobre:
            AboutView(path: path, onSelectSection: selectSection)

        case .spriteDemo:
            SpriteDemoView(path: path, onSelectSection: selectSection)

        case .studentMessages(let category):
            StudentMessagesView(path: path, category: category, onSelectSection: selectSection)

        case .studentFeedbacks(let category):
            StudentFeedbacksView(path: path, category: category, onSelectSection: selectSection)

        case .studentTeachers(let studentEmail):
            StudentTeachersView(
                path: path,
                studentEmail: studentEmail,
                onSelectSection: selectSection
            )

        default:
            EmptyView()
        }
    }
}
