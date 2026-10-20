import SwiftUI

private struct CompactDestructiveAgendaActionButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppThemeAdaptiveColor(isEnabled ? .white.opacity(0.92) : .white.opacity(0.55)))
            .padding(.vertical, 9)
            .background(AppThemeAdaptiveColor(isEnabled ? Color.red.opacity(0.20) : Color.white.opacity(0.10)))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        // Tema Claro: contorno verde-escuro (#294A2F); Tema Escuro mantém o original
                        appTheme == .light
                            ? AnyShapeStyle(NextFitLightColors.chevron)
                            : AnyShapeStyle(AppThemeAdaptiveColor(isEnabled ? Color.red.opacity(0.35) : Color.white.opacity(0.12))),
                        lineWidth: 1
                    )
            )
    }
}

// Botão "Agendar": no Tema Claro (habilitado) usa o padrão do botão Sair da ProfileView
// (verde militar 80%/90% e texto branco), mantendo as dimensões do `compactPrimaryGreenActionButton()`.
// Tema Escuro e estado desabilitado permanecem com o estilo original.
private struct CompactScheduleAgendaActionButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        if appTheme == .light && isEnabled {
            content
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, 9)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(NextFitLightColors.chevron, lineWidth: 1)
                )
        } else if appTheme == .light {
            // Tema Claro (desabilitado/processando): estilo original com contorno verde-escuro (#294A2F)
            content
                .compactPrimaryGreenActionButton()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(NextFitLightColors.chevron, lineWidth: 1)
                )
        } else {
            content
                .compactPrimaryGreenActionButton()
        }
    }
}

private extension View {
    func compactDestructiveAgendaActionButton() -> some View {
        modifier(CompactDestructiveAgendaActionButtonModifier())
    }

    func compactScheduleAgendaActionButton() -> some View {
        modifier(CompactScheduleAgendaActionButtonModifier())
    }
}

// Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView; Tema Escuro usa os valores originais)
private enum NextFitLightColors {
    static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
    static let innerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255) // #F0F7EF
    static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)  // #85C995
    static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
    static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
    static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)      // #294A2F
    static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
}

private struct NextFitCardStyle: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppThemeColor(dark: Color.black.opacity(0.68), light: NextFitLightColors.cardSurface))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: NextFitLightColors.chevron), lineWidth: 1)
            )
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
    }
}

struct StudentNextFitWodView: View {
    @Binding var path: [AppRoute]
    let studentId: String
    let onSelectSection: (StudentMainSection) -> Void

    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme
    @StateObject private var viewModel: StudentDashboardViewModel
    @State private var isNextFitLogoutConfirmationPresented = false
    @State private var isNextFitLogoutErrorPresented = false
    // Indica se a consulta inicial do WOD já foi concluída (evita estado vazio antes da consulta)
    @State private var hasFinishedInitialNextFitLoad = false

    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        onSelectSection: @escaping (StudentMainSection) -> Void,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.onSelectSection = onSelectSection
        _viewModel = StateObject(wrappedValue: StudentDashboardViewModel(studentId: studentId, repository: repository))
    }

    var body: some View {
        ZStack {
            AppThemeBackgroundImage()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            nextFitContent
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    path.removeLast()
                } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("dashboard.wod.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.hasNextFitSession {
                    nextFitLogoutButton
                }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
        .onAppear {
            Task {
                await viewModel.loadNextFit(locale: locale)
                hasFinishedInitialNextFitLoad = true
            }
        }
        .onChange(of: viewModel.needsNextFitAuthentication) { _, needsAuthentication in
            if needsAuthentication, path.last == .studentNextFitWod {
                path.removeLast()
            }
        }
        .alert("dashboard.could_not_disconnect_from_nextfit", isPresented: $isNextFitLogoutErrorPresented) {
            Button("common.ok", role: .cancel) { }
        } message: {
            Text("dashboard.try_again_message")
        }
    }

    private var nextFitLogoutButton: some View {
        Button {
            isNextFitLogoutConfirmationPresented = true
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Colors.icon(Theme.Colors.ink(0.55)))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoadingNextFitWod)
        .accessibilityLabel("dashboard.disconnect_nextfit")
        .confirmationDialog(
            "dashboard.disconnect_nextfit_confirmation_title",
            isPresented: $isNextFitLogoutConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("dashboard.disconnect", role: .destructive) {
                do {
                    try viewModel.logoutNextFit()
                } catch {
                    isNextFitLogoutErrorPresented = true
                }
            }
            Button("common.cancel", role: .cancel) { }
        } message: {
            Text("dashboard.you_will_need_to_sign_in_again_to_view_today_s_wod")
        }
    }

    @ViewBuilder
    private var nextFitContent: some View {
        if viewModel.isLoadingNextFitWod || !hasFinishedInitialNextFitLoad {
            ProgressView()
                .tint(Theme.Colors.ink())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if viewModel.needsNextFitAuthentication {
            EmptyView()
        } else if let error = viewModel.nextFitError {
            VStack(alignment: .leading, spacing: 14) {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                Button {
                    Task { await viewModel.retryNextFitWod(locale: locale) }
                } label: {
                    Text("dashboard.try_again_action")
                        .padding(.horizontal, 14)
                        .compactPrimaryGreenActionButton()
                        // Tema Claro: contorno verde-escuro (#294A2F); Tema Escuro inalterado
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppThemeColor(dark: .clear, light: NextFitLightColors.chevron), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .modifier(NextFitCardStyle())
        } else {
            nextFitAgendaDateSelector

            nextFitTabSelector

            if viewModel.isNextFitAgendaSelected {
                nextFitAgendaContent
                    .modifier(NextFitCardStyle())
            } else {
                nextFitSelectedDateWodContent
            }
        }
    }

    // MARK: - Dados da data selecionada

    private var isTodayAgendaDateSelected: Bool {
        Calendar.current.isDate(
            viewModel.selectedNextFitAgendaDate,
            inSameDayAs: viewModel.todayAgendaDate
        )
    }

    /// Hoje: WODs carregados em `loadTodayWods`. Demais datas: WODs da data selecionada.
    private var displayedNextFitWods: [NextFitWodDisplay] {
        isTodayAgendaDateSelected ? viewModel.nextFitWods : viewModel.nextFitAgendaWods
    }

    private var displayedNextFitWod: NextFitWodDisplay? {
        guard !viewModel.isNextFitAgendaSelected else { return nil }
        if case let .wod(modalityId)? = viewModel.selectedNextFitContent,
           let wod = displayedNextFitWods.first(where: { $0.modalityId == modalityId }) {
            return wod
        }
        return displayedNextFitWods.first
    }

    private var isLoadingSelectedDateWods: Bool {
        !isTodayAgendaDateSelected
            && (viewModel.isLoadingNextFitAgenda || viewModel.isLoadingNextFitAgendaWods)
    }

    private var nextFitTabOptions: [StudentDashboardNextFitContentOption] {
        let modalities: [(id: Int, name: String)]
        if isLoadingSelectedDateWods {
            // Durante a troca de data, mantém as abas das modalidades previstas para a data
            // (mesmo filtro usado no carregamento), evitando que o seletor encolha só para AGENDA.
            let calendar = Calendar.current
            var modalityIds = Set<Int>()
            modalities = viewModel.nextFitUpcomingWods
                .filter {
                    calendar.isDate($0.date, inSameDayAs: viewModel.selectedNextFitAgendaDate)
                        && modalityIds.insert($0.modalityId).inserted
                }
                .map { (id: $0.modalityId, name: $0.modalityName) }
        } else {
            modalities = displayedNextFitWods.map { (id: $0.modalityId, name: $0.modalityName) }
        }
        return modalities.map {
            .wod(id: $0.id, title: $0.name)
        } + [
            .agenda
        ]
    }

    /// Modalidade destacada nas abas, derivada de `selectedNextFitContent`.
    private var highlightedNextFitModalityId: Int? {
        guard !viewModel.isNextFitAgendaSelected else { return nil }
        guard isLoadingSelectedDateWods else { return displayedNextFitWod?.modalityId }

        let modalityIds = nextFitTabOptions.compactMap { option -> Int? in
            if case let .wod(modalityId, _) = option { return modalityId }
            return nil
        }
        if case let .wod(modalityId)? = viewModel.selectedNextFitContent,
           modalityIds.contains(modalityId) {
            return modalityId
        }
        return modalityIds.first
    }

    // MARK: - Abas

    // Apresentação: modalidades agrupadas em um único controle segmentado e AGENDA como botão independente.
    // Ordem e montagem das opções permanecem as de `nextFitTabOptions`.
    private var nextFitTabSelector: some View {
        let options = nextFitTabOptions
        let modalityOptions = options.filter { $0.selection != .agenda }
        let agendaOptions = options.filter { $0.selection == .agenda }

        return HStack(spacing: 8) {
            if !modalityOptions.isEmpty {
                HStack(spacing: 0) {
                    ForEach(modalityOptions) { option in
                        nextFitSegmentButton(option)
                    }
                }
                .padding(3)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppThemeColor(dark: Color.black.opacity(0.68), light: NextFitLightColors.cardSurface))
                        // Profundidade apenas no Tema Claro (mesmo padrão dos botões não selecionados)
                        .shadow(
                            color: appTheme == .light ? .black.opacity(0.25) : .clear,
                            radius: appTheme == .light ? 10 : 0,
                            y: appTheme == .light ? 6 : 0
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: NextFitLightColors.chevron), lineWidth: 1)
                )

                ForEach(agendaOptions) { option in
                    nextFitTabButton(option, horizontalPadding: 16)
                        .fixedSize(horizontal: true, vertical: false)
                }
            } else {
                ForEach(agendaOptions) { option in
                    nextFitTabButton(option)
                }
            }
        }
    }

    // Segmento de modalidade dentro do contêiner agrupado: selecionado com preenchimento
    // (verde militar no Tema Claro / verde original no Tema Escuro); não selecionado transparente, sem borda.
    private func nextFitSegmentButton(_ option: StudentDashboardNextFitContentOption) -> some View {
        let isSelected: Bool = {
            switch option.selection {
            case .agenda:
                return viewModel.isNextFitAgendaSelected
            case .wod(let modalityId):
                return highlightedNextFitModalityId == modalityId
            }
        }()

        let isLightSelected = appTheme == .light && isSelected

        return Button {
            let selection = option.selection
            viewModel.selectedNextFitContent = selection
            if selection != .agenda {
                viewModel.clearNextFitAgendaDetail()
            }
        } label: {
            nextFitContentOptionLabel(option)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(
                    isLightSelected
                        ? AnyShapeStyle(Color.white)
                        : AnyShapeStyle(AppThemeColor(dark: Color.white, light: NextFitLightColors.primaryText))
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            isLightSelected
                                ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                                : isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            Theme.Colors.primaryGreen.opacity(0.55),
                                            Theme.Colors.primaryGreen.opacity(0.25)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(Color.clear)
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func nextFitTabButton(_ option: StudentDashboardNextFitContentOption, horizontalPadding: CGFloat = 6) -> some View {
        let isSelected: Bool = {
            switch option.selection {
            case .agenda:
                return viewModel.isNextFitAgendaSelected
            case .wod(let modalityId):
                return highlightedNextFitModalityId == modalityId
            }
        }()

        let isLightSelected = appTheme == .light && isSelected

        return Button {
            let selection = option.selection
            viewModel.selectedNextFitContent = selection
            if selection != .agenda {
                viewModel.clearNextFitAgendaDetail()
            }
        } label: {
            nextFitContentOptionLabel(option)
                .font(.system(size: 15, weight: .semibold))
                // Tema Claro: aba selecionada com o padrão do botão Sair (verde militar 80%/90% e texto branco)
                .foregroundStyle(
                    isLightSelected
                        ? AnyShapeStyle(Color.white)
                        : AnyShapeStyle(AppThemeColor(dark: Color.white, light: NextFitLightColors.primaryText))
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, horizontalPadding)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isLightSelected
                                ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                                : isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            Theme.Colors.primaryGreen.opacity(0.55),
                                            Theme.Colors.primaryGreen.opacity(0.25)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(AppThemeColor(dark: Color.black.opacity(0.68), light: NextFitLightColors.cardSurface))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isLightSelected
                                ? AnyShapeStyle(NextFitLightColors.chevron)
                                : isSelected
                                ? AnyShapeStyle(Theme.Colors.primaryGreen.opacity(0.85))
                                : AnyShapeStyle(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: NextFitLightColors.chevron)),
                            lineWidth: 1
                        )
                )
                // Selecionado: brilho verde original (ambos os temas). Nao selecionado: profundidade apenas no Tema Claro
                .shadow(
                    color: isSelected ? Theme.Colors.primaryGreen.opacity(0.35) : (appTheme == .light ? .black.opacity(0.25) : .clear),
                    radius: isSelected ? 8 : (appTheme == .light ? 10 : 0),
                    y: isSelected ? 0 : (appTheme == .light ? 6 : 0)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Treino da data selecionada

    @ViewBuilder
    private var nextFitSelectedDateWodContent: some View {
        if isLoadingSelectedDateWods {
            ProgressView()
                .tint(Theme.Colors.ink())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if !isTodayAgendaDateSelected, let error = viewModel.nextFitAgendaWodError {
            VStack(alignment: .leading, spacing: 14) {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                Button {
                    Task {
                        await viewModel.selectNextFitAgendaDate(
                            viewModel.selectedNextFitAgendaDate,
                            locale: locale
                        )
                    }
                } label: {
                    Text("dashboard.try_again_action")
                        .padding(.horizontal, 14)
                        .compactPrimaryGreenActionButton()
                        // Tema Claro: contorno verde-escuro (#294A2F); Tema Escuro inalterado
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppThemeColor(dark: .clear, light: NextFitLightColors.chevron), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .modifier(NextFitCardStyle())
        } else if let wod = displayedNextFitWod {
            nextFitWodBanner(wod)

            if wod.activities.isEmpty {
                nextFitEmptyWodMessage
            } else {
                ForEach(wod.activities) { activity in
                    nextFitActivityCard(activity)
                }
            }
        } else {
            nextFitEmptyWodMessage
        }
    }

    private var nextFitEmptyWodMessage: some View {
        Text(
            isTodayAgendaDateSelected
                ? LocalizedStringKey("dashboard.no_wod_available_for_today")
                : LocalizedStringKey("dashboard.no_workout_scheduled")
        )
        .font(.system(size: 14))
        .foregroundStyle(Theme.Colors.ink(0.55))
        .modifier(NextFitCardStyle())
    }

    private func nextFitWodBanner(_ wod: NextFitWodDisplay) -> some View {
        let unitName = viewModel.studentUnitName

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.16), light: NextFitLightColors.iconSurface))
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.35), light: NextFitLightColors.border), lineWidth: 1)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: NextFitLightColors.iconInk))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 2) {
                Text("dashboard.wod.banner_title")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink())

                if !unitName.isEmpty {
                    Text(verbatim: unitName)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.ink(0.75))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text(verbatim: wod.modalityName.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.accentForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.Colors.glass(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.Colors.primaryGreen.opacity(0.45), lineWidth: 1)
                )
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background {
            ZStack {
                Image("rdv_crossfit_wod_horizontal")
                    .resizable()
                    .scaledToFill()

                // Tema Claro: camada mais leve para deixar a foto mais viva (mais intensa à esquerda, nos textos)
                AppThemeNeutralGradient(
                    colors: appTheme == .light
                        ? [
                            Color.black.opacity(0.70),
                            Color.black.opacity(0.35),
                            Color.black.opacity(0.12)
                        ]
                        : [
                            Color.black.opacity(0.92),
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.35)
                        ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .clipped()
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: NextFitLightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func nextFitActivityCard(_ activity: NextFitWodActivityDisplay) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: nextFitActivityIconName(for: activity.title))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: NextFitLightColors.iconInk))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 8) {
                Text(activity.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: NextFitLightColors.primaryText))

                Text(activity.description)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Colors.ink(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Tema Claro: verde pastel solido, sem sobreposicao
                AppThemeColor(dark: Color.black.opacity(0.68), light: NextFitLightColors.cardSurface)
                AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.05), light: .clear)
            }
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: NextFitLightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    /// Ícone apenas visual, escolhido pelo título real da atividade retornado pela API.
    private func nextFitActivityIconName(for title: String) -> String {
        let normalized = title
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
            .lowercased()

        if normalized.contains("warm") || normalized.contains("aquec") {
            return "list.bullet"
        }
        if normalized.contains("skill") || normalized.contains("tecnic") || normalized.contains("habilidade") {
            return "figure.gymnastics"
        }
        if normalized.contains("wod") || normalized.contains("metcon") {
            return "trophy.fill"
        }
        if normalized.contains("rx") || normalized.contains("forca") || normalized.contains("strength") {
            return "bolt.fill"
        }
        return "dumbbell.fill"
    }


    @ViewBuilder
    private var nextFitAgendaContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.isLoadingNextFitAgenda || viewModel.isLoadingNextFitAgendaDetail {
                ProgressView()
                    .tint(Theme.Colors.ink())
            } else if let detail = viewModel.selectedNextFitAgendaDetail {
                nextFitAgendaDetailContent(detail)
            } else if let error = viewModel.nextFitAgendaDetailError {
                nextFitAgendaDetailErrorContent(error)
            } else if let error = viewModel.nextFitAgendaError {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                Button {
                    Task { await viewModel.selectNextFitAgendaDate(viewModel.selectedNextFitAgendaDate, locale: locale) }
                } label: {
                    Text("dashboard.try_again_action")
                        .padding(.horizontal, 14)
                        .compactPrimaryGreenActionButton()
                        // Tema Claro: contorno verde-escuro (#294A2F); Tema Escuro inalterado
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppThemeColor(dark: .clear, light: NextFitLightColors.chevron), lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else if viewModel.nextFitAgenda.isEmpty {
                Text("dashboard.no_time_available_for_this_date")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.nextFitAgenda) { entry in
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                Task { await viewModel.selectNextFitAgenda(entry.id, locale: locale) }
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        nextFitAgendaDetailRow(
                                            icon: "clock",
                                            text: entry.scheduleText(locale: locale),
                                            font: .system(size: 14, weight: .medium),
                                            textColor: .white.opacity(0.92)
                                        )
                                        Spacer()
                                        nextFitAgendaDetailRow(
                                            icon: "person.2.fill",
                                            text: entry.capacityText,
                                            font: .system(size: 14, weight: .medium),
                                            textColor: .white.opacity(0.92)
                                        )
                                    }
                                    nextFitAgendaDetailRow(
                                        icon: "dumbbell.fill",
                                        text: entry.modalityName,
                                        font: .system(size: 16, weight: .semibold),
                                        // Tema Claro: verde militar do botão Agendar habilitado; Tema Escuro inalterado
                                        textColor: appTheme == .light
                                            ? AppThemePalette.lightBar.opacity(0.80)
                                            : Theme.Colors.primaryGreen
                                    )
                                    nextFitAgendaDetailRow(
                                        icon: "person.fill",
                                        text: entry.instructorName,
                                        textColor: .white.opacity(0.92)
                                    )
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)

                            HStack {
                                nextFitAgendaDetailRow(
                                    icon: "mappin.and.ellipse",
                                    text: entry.locationName,
                                    textColor: .white.opacity(0.55)
                                )
                                Spacer()
                                agendaCheckInButton(for: entry)
                            }
                            if let error = viewModel.agendaActionError(for: entry.id) {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red.opacity(0.9))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppThemeColor(dark: Color.white.opacity(0.06), light: NextFitLightColors.innerSurface))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: NextFitLightColors.chevron), lineWidth: 1)
                        )
                        // Profundidade apenas no Tema Claro (padrão da AdminProfileSelectionView)
                        .shadow(
                            color: appTheme == .light ? .black.opacity(0.25) : .clear,
                            radius: appTheme == .light ? 10 : 0,
                            y: appTheme == .light ? 6 : 0
                        )
                    }
                }
            }
        }
    }

    private var nextFitAgendaDateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.nextFitAgendaDates, id: \.self) { date in
                    nextFitAgendaDateButton(date: date)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func nextFitContentOptionLabel(
        _ option: StudentDashboardNextFitContentOption
    ) -> some View {
        switch option {
        case .wod(_, let title):
            Text(verbatim: title.uppercased())
        case .agenda:
            Text(DashboardMode.agenda.localizedTitle)
        }
    }

    private func nextFitAgendaDateButton(date: Date) -> some View {
        let calendar = Calendar.current
        let isSelected = calendar.isDate(
            viewModel.selectedNextFitAgendaDate,
            inSameDayAs: date
        )
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "dd/MM"
        // Tema Claro: data selecionada com o padrão do botão Sair (verde militar 80%/90% e texto branco)
        let isLightSelected = appTheme == .light && isSelected
        return Button {
            Task { await viewModel.selectNextFitAgendaDate(date, locale: locale) }
        } label: {
            VStack(spacing: 4) {
                Text(verbatim: nextFitAgendaDayTitle(for: date))
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .fixedSize()

                Text(verbatim: formatter.string(from: date))
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
            }
            .foregroundStyle(
                isLightSelected
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(AppThemeAdaptiveColor(isSelected ? Theme.Colors.primaryGreen : .white.opacity(0.85)))
            )
            .frame(minWidth: 58)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isLightSelected
                            ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                            : isSelected
                                ? AnyShapeStyle(Theme.Colors.primaryGreen.opacity(0.18))
                                : AnyShapeStyle(AppThemeColor(dark: Color.black.opacity(0.68), light: NextFitLightColors.cardSurface))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isLightSelected
                            ? AnyShapeStyle(NextFitLightColors.chevron)
                            : isSelected
                                ? AnyShapeStyle(Theme.Colors.primaryGreen.opacity(0.85))
                                : AnyShapeStyle(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: NextFitLightColors.chevron)),
                        lineWidth: 1
                    )
            )
            // Selecionado: brilho verde original (ambos os temas). Nao selecionado: profundidade apenas no Tema Claro
            .shadow(
                color: isSelected ? Theme.Colors.primaryGreen.opacity(0.35) : (appTheme == .light ? .black.opacity(0.25) : .clear),
                radius: isSelected ? 6 : (appTheme == .light ? 10 : 0),
                y: isSelected ? 0 : (appTheme == .light ? 6 : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// "HOJE", "AMANHÃ" ou o dia da semana abreviado (ex.: "QUA"), conforme o idioma do app.
    private func nextFitAgendaDayTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: viewModel.todayAgendaDate) {
            return DashboardAgendaDay.today.title(locale: locale)
        }
        if calendar.isDate(date, inSameDayAs: viewModel.tomorrowAgendaDate) {
            return DashboardAgendaDay.tomorrow.title(locale: locale)
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
            .replacingOccurrences(of: ".", with: "")
            .uppercased(with: locale)
    }

    private func nextFitAgendaDetailContent(_ detail: NextFitAgendaDetailDisplay) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                viewModel.clearNextFitAgendaDetail()
            } label: {
                Label {
                    Text(LocalizedStringKey("dashboard.back_to_schedule"))
                } icon: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: NextFitLightColors.chevron))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.accentForeground)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    nextFitAgendaDetailRow(icon: "calendar", text: detail.dateText)
                    Spacer()
                    nextFitAgendaDetailRow(icon: "person.2.fill", text: detail.capacityText)
                }
                nextFitAgendaDetailRow(icon: "clock", text: detail.scheduleText)
                nextFitAgendaDetailRow(icon: "dumbbell.fill", text: detail.modalityName)
                nextFitAgendaDetailRow(icon: "person.fill", text: detail.instructorName)
                nextFitAgendaDetailRow(icon: "mappin.and.ellipse", text: detail.locationName)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppThemeColor(dark: Color.white.opacity(0.06), light: NextFitLightColors.innerSurface))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppThemeColor(dark: Color.white.opacity(0.08), light: NextFitLightColors.chevron), lineWidth: 1))

            Text("dashboard.participants")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.ink(0.92))

            if detail.participants.isEmpty {
                Text("dashboard.no_participant_at_this_time")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            } else {
                ForEach(detail.participants) { participant in
                    // Ícone conforme `Participantes[].Status` individual (1: mensalista; 2: acesso flexível).
                    // Status ausente ou desconhecido: somente o nome, como antes.
                    let statusSymbol: String? = {
                        switch participant.status {
                        case 1: return "checkmark.seal.fill"
                        case 2: return "point.3.connected.trianglepath.dotted"
                        default: return nil
                        }
                    }()

                    HStack(spacing: 6) {
                        if let statusSymbol {
                            Image(systemName: statusSymbol)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.ink(0.92))
                                .accessibilityHidden(true)
                        }

                        Text(participant.name)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.ink(0.92))
                    }
                }
            }

            if let entry = viewModel.nextFitAgenda.first(where: { $0.id == detail.id }) {
                HStack {
                    Spacer()
                    agendaCheckInButton(for: entry)
                }
            }

            if let error = viewModel.agendaActionError(for: detail.id) {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
    }

    private func nextFitAgendaDetailErrorContent(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                viewModel.clearNextFitAgendaDetail()
            } label: {
                Label {
                    Text(LocalizedStringKey("dashboard.back_to_schedule"))
                } icon: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: NextFitLightColors.chevron))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.accentForeground)
            }
            .buttonStyle(.plain)

            Text(error)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))

            Button {
                Task { await viewModel.retryNextFitAgendaDetail(locale: locale) }
            } label: {
                Text("dashboard.try_again_action")
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
                    // Tema Claro: contorno verde-escuro (#294A2F); Tema Escuro inalterado
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppThemeColor(dark: .clear, light: NextFitLightColors.chevron), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func nextFitAgendaDetailRow(
        icon: String,
        text: String,
        font: Font = .system(size: 14),
        textColor: Color = .white.opacity(0.92)
    ) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: NextFitLightColors.iconInk))
                .frame(width: 18)
        }
        .font(font)
        .foregroundStyle(AppThemeAdaptiveColor(textColor))
    }

    @ViewBuilder
    private func agendaCheckInButton(for entry: NextFitAgendaDisplay) -> some View {
        if viewModel.isAgendaWithdrawal(entry.id) {
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle")
                Text("dashboard.withdrawn")
            }
            .padding(.horizontal, 14)
            .compactDestructiveAgendaActionButton()
            .accessibilityLabel("dashboard.withdrawn")
        } else if entry.endDate < Date() {
            Button { } label: {
                HStack(spacing: 10) {
                    Image(systemName: "clock.badge.xmark")
                    Text("dashboard.closed")
                }
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
                    // Tema Claro: contorno verde-escuro (#294A2F); Tema Escuro inalterado
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppThemeColor(dark: .clear, light: NextFitLightColors.chevron), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(true)
        } else {
            agendaCheckInButton(for: entry.id)
        }
    }

    @ViewBuilder
    private func agendaCheckInButton(for agendaId: Int) -> some View {
        let isProcessing = viewModel.isProcessingAgenda(agendaId)
        if viewModel.canCancelAgendaCheckIn(agendaId) {
            Button {
                Task { await viewModel.cancelAgendaCheckIn(agendaId, locale: locale) }
            } label: {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Image(systemName: "xmark.circle")
                    }
                    Text("common.cancel")
                }
                .padding(.horizontal, 14)
                .compactDestructiveAgendaActionButton()
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .popover(
                isPresented: Binding(
                    get: { viewModel.agendaCancellationConfirmation?.agendaId == agendaId },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.dismissAgendaCancellationConfirmation()
                        }
                    }
                ),
                arrowEdge: .bottom
            ) {
                agendaCancellationConfirmationCard
                    .presentationCompactAdaptation(.popover)
            }
        } else {
            Button {
                Task { await viewModel.checkInAgenda(agendaId, locale: locale) }
            } label: {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                    } else if appTheme == .light {
                        // Tema Claro: ícone herda o branco do botão (contraste sobre o verde militar)
                        Image(systemName: "calendar.badge.plus")
                    } else {
                        Image(systemName: "calendar.badge.plus")
                            .appThemeIconForeground()
                    }
                    Text("dashboard.schedule")
                }
                .padding(.horizontal, 14)
                .compactScheduleAgendaActionButton()
            }
            .buttonStyle(.plain)
            .disabled(isProcessing || !viewModel.canScheduleAgendaCheckIn(agendaId))
        }
    }

    private var agendaCancellationConfirmationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("dashboard.confirm_cancellation")
                .font(.system(size: 17, weight: .semibold))

            Text(viewModel.agendaCancellationConfirmation?.question ?? "")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            HStack {
                Button("common.cancel", role: .cancel) {
                    viewModel.dismissAgendaCancellationConfirmation()
                }

                Spacer()

                Button("common.confirm", role: .destructive) {
                    Task { await viewModel.confirmAgendaCancellation(locale: locale) }
                }
            }
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
    }
}
