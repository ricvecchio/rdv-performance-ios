import SwiftUI

/// Contexto de uso do Menu compartilhado. Define quais itens e qual rodapé são apresentados.
enum MenuContext {
    case student
    case teacher
}

/// Tela Menu compartilhada entre Aluno e Professor: centraliza o acesso às funcionalidades
/// que antes ficavam no rodapé.
///
/// Reutiliza as telas existentes — a navegação é feita pela raiz de cada tipo de usuário
/// (`StudentRootView` / `TeacherRootView`), com callbacks independentes por contexto.
struct MenuView: View {

    let context: MenuContext
    @Binding var path: [AppRoute]
    let onBack: () -> Void
    /// Callbacks do aluno (ignorados no contexto professor).
    var onSelectSection: (StudentMainSection) -> Void = { _ in }
    /// Abre diretamente Anotações, Lembretes ou Aniversários (aluno).
    var onOpenOrganizer: (PersonalOrganizerSection) -> Void = { _ in }
    /// Callback do professor (ignorado no contexto aluno).
    var onSelectTeacherSection: (TeacherMainSection) -> Void = { _ in }
    /// Categoria de treino do professor (usada ao abrir Meus Recordes).
    var teacherCategory: TreinoTipo = .crossfit

    /// Treinos só existe para alunos com professor vinculado (regra já existente do rodapé).
    @Environment(\.studentShowsWorkoutsTab) private var showsWorkouts
    @EnvironmentObject private var session: AppSession

    /// Estado da sessão NextFit da conta atual (mesma fonte do `StudentDashboardViewModel.hasNextFitSession`).
    /// `nil` enquanto ainda não foi lido: nesse caso o indicador não é exibido.
    @State private var hasNextFitSession: Bool? = nil
    @State private var isNextFitLoginSheetPresented = false

    var body: some View {
        Group {
            switch context {
            case .student:
                studentMenu
            case .teacher:
                teacherMenu
            }
        }
        // Desfoca o menu ao fundo enquanto o modal "Entrar no NextFit" está aberto (o modal permanece nítido)
        .blur(radius: isNextFitLoginSheetPresented ? 8 : 0)
        .animation(.easeInOut(duration: 0.18), value: isNextFitLoginSheetPresented)
        // Reavalia ao abrir/voltar ao Menu (após login ou logout feitos na tela WOD do dia)
        .onAppear(perform: refreshNextFitSession)
        .onChange(of: session.uid) { _, _ in refreshNextFitSession() }
        // Mesmo modal "Entrar no NextFit" da Home do aluno; ao fechar, reavalia a sessão
        .sheet(isPresented: $isNextFitLoginSheetPresented, onDismiss: refreshNextFitSession) {
            MenuNextFitLoginSheet(
                studentId: session.uid ?? "",
                isPresented: $isNextFitLoginSheetPresented
            )
            .presentationDetents([.fraction(0.50)])
        }
    }

    /// Toque na linha do WOD do dia: sem sessão NextFit abre o modal "Entrar no NextFit"; com sessão, navega ao WOD.
    private func openWodOrNextFitLogin() {
        if hasNextFitSession == false {
            isNextFitLoginSheetPresented = true
        } else {
            path.append(.studentNextFitWod)
        }
    }

    private func refreshNextFitSession() {
        guard let uid = session.uid, !uid.isEmpty else {
            hasNextFitSession = nil
            return
        }
        hasNextFitSession = NextFitService().hasSession(sessionAccount: uid)
    }

    // MARK: - Aluno

    private var studentMenu: some View {
        PersonalScreenScaffold(
            titleKey: "menu.title",
            onBack: onBack,
            onSelectSection: onSelectSection
        ) {

            category("menu.category.training") {
                menuRow(icon: "trophy.fill", titleKey: "ui.my_records") {
                    onSelectSection(.records)
                }
                menuRow(
                    icon: "dumbbell.fill",
                    titleKey: "menu.wod",
                    showsSignedOutIndicator: hasNextFitSession == false,
                    onConnectNextFit: hasNextFitSession == false ? { isNextFitLoginSheetPresented = true } : nil
                ) {
                    openWodOrNextFitLogin()
                }
                if showsWorkouts {
                    menuRow(icon: "figure.strengthtraining.traditional", titleKey: "menu.workouts") {
                        onSelectSection(.agenda)
                    }
                }
            }

            category("menu.category.personal") {
                menuRow(icon: "calendar.badge.clock", titleKey: "menu.my_routine") {
                    onOpenOrganizer(.notes)
                }
                menuRow(icon: "video.fill", titleKey: "workout.my_videos") {
                    path.append(.studentVideos)
                }
            }

            category("menu.category.explore") {
                menuRow(icon: "magnifyingglass", titleKey: "menu.athletes") {
                    path.append(.studentComingSoon(titleKey: "menu.search_athletes"))
                }
                menuRow(icon: "trophy", titleKey: "menu.championships") {
                    path.append(.studentComingSoon(titleKey: "menu.search_championships"))
                }
            }
        }
    }

    // MARK: - Professor

    private var teacherMenu: some View {
        PersonalScreenScaffold(
            titleKey: "menu.title",
            onBack: onBack,
            onSelectSection: onSelectSection
        ) {
            category("menu.category.training_management") {
                menuRow(icon: "person.3", titleKey: "common.students") {
                    onSelectTeacherSection(.students)
                }
                menuRow(icon: "figure.strengthtraining.traditional", titleKey: "menu.workouts") {
                    onSelectTeacherSection(.workouts)
                }
            }

            category("menu.category.my_training") {
                menuRow(icon: "trophy.fill", titleKey: "ui.my_records") {
                    path.append(.teacherPersonalRecords(category: teacherCategory))
                }
                menuRow(
                    icon: "dumbbell.fill",
                    titleKey: "menu.wod",
                    showsSignedOutIndicator: hasNextFitSession == false,
                    onConnectNextFit: hasNextFitSession == false ? { isNextFitLoginSheetPresented = true } : nil
                ) {
                    openWodOrNextFitLogin()
                }
            }

            category("menu.category.personal") {
                menuRow(icon: "calendar.badge.clock", titleKey: "menu.my_routine") {
                    onSelectTeacherSection(.reminders)
                }
            }

            category("menu.category.explore") {
                menuRow(icon: "magnifyingglass", titleKey: "menu.athletes") {
                    path.append(.studentComingSoon(titleKey: "menu.search_athletes"))
                }
                menuRow(icon: "trophy", titleKey: "menu.championships") {
                    path.append(.studentComingSoon(titleKey: "menu.search_championships"))
                }
            }
        }
    }

    private func category<Rows: View>(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder rows: () -> Rows
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .padding(.horizontal, 6)

            rows()
        }
    }

    private func menuRow(
        icon: String,
        titleKey: LocalizedStringKey,
        showsSignedOutIndicator: Bool = false,
        onConnectNextFit: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PersonalRowIcon(systemName: icon)

                Text(titleKey)
                    .font(.system(size: 17, weight: .semibold))
                    .modifier(PersonalPrimaryTextStyle())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if showsSignedOutIndicator {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                        Text("menu.wod_logged_out")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(
                        AppThemeColor(
                            dark: Color.white.opacity(0.35),
                            light: PersonalOrganizerLightColors.chevron
                        )
                    )
            }
            .modifier(StudentMenuCardModifier())
        }
        .buttonStyle(.plain)
        // Botão Conectar (apenas WOD do dia sem sessão NextFit): fica fora do Button do card para não disparar a navegação
        .overlay(alignment: .trailing) {
            if let onConnectNextFit {
                Button(action: onConnectNextFit) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(AppThemeColor(dark: Color.green.opacity(0.14), light: PersonalOrganizerLightColors.iconSurface))
                            .frame(width: 34, height: 34)

                        Image(systemName: "link")
                            .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: PersonalOrganizerLightColors.iconInk))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("dashboard.connect_nextfit")
                .padding(.trailing, 34)
            }
        }
    }
}

/// Hospeda o modal "Entrar no NextFit" da Home do aluno (`StudentDashboardView.NextFitLoginSheetView`),
/// usando a mesma autenticação (`StudentDashboardViewModel.authenticateNextFit`) e os mesmos erros.
private struct MenuNextFitLoginSheet: View {
    let studentId: String
    @Binding var isPresented: Bool

    @StateObject private var viewModel: StudentDashboardViewModel
    @State private var email = ""
    @State private var password = ""

    init(studentId: String, isPresented: Binding<Bool>) {
        self.studentId = studentId
        self._isPresented = isPresented
        _viewModel = StateObject(
            wrappedValue: StudentDashboardViewModel(studentId: studentId, repository: .shared)
        )
    }

    var body: some View {
        StudentDashboardView.NextFitLoginSheetView(
            viewModel: viewModel,
            nextFitEmailInput: $email,
            nextFitPasswordInput: $password,
            isNextFitLoginSheetPresented: $isPresented
        )
    }
}

/// Igual a `PersonalCardModifier`, alterando somente o fundo do Tema Claro (#DDEDDC).
private struct StudentMenuCardModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    private static let lightSurface = Color(
        red: 0xDD / 255,
        green: 0xED / 255,
        blue: 0xDC / 255
    )

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    AppThemeColor(dark: Color.black.opacity(0.90), light: Self.lightSurface)

                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.05), light: .clear)
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppThemeColor(
                            dark: Theme.Colors.primaryGreen.opacity(0.28),
                            light: PersonalOrganizerLightColors.chevron
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
    }
}
