import SwiftUI

private struct CompactDestructiveAgendaActionButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isEnabled ? .white.opacity(0.92) : .white.opacity(0.55))
            .padding(.vertical, 9)
            .background(isEnabled ? Color.red.opacity(0.20) : Color.white.opacity(0.10))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isEnabled ? Color.red.opacity(0.35) : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
    }
}

private extension View {
    func compactDestructiveAgendaActionButton() -> some View {
        modifier(CompactDestructiveAgendaActionButtonModifier())
    }
}

private struct NextFitCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.68))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
            )
    }
}

struct StudentNextFitWodView: View {
    @Binding var path: [AppRoute]
    let studentId: String
    let onSelectSection: (StudentMainSection) -> Void

    @Environment(\.locale) private var locale
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
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
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
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("dashboard.wod.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
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
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                .foregroundColor(.white.opacity(0.55))
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
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if viewModel.needsNextFitAuthentication {
            EmptyView()
        } else if let error = viewModel.nextFitError {
            VStack(alignment: .leading, spacing: 14) {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                Button {
                    Task { await viewModel.retryNextFitWod(locale: locale) }
                } label: {
                    Text("dashboard.try_again_action")
                        .padding(.horizontal, 14)
                        .compactPrimaryGreenActionButton()
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

    private var nextFitTabSelector: some View {
        HStack(spacing: 8) {
            ForEach(nextFitTabOptions) { option in
                nextFitTabButton(option)
            }
        }
    }

    private func nextFitTabButton(_ option: StudentDashboardNextFitContentOption) -> some View {
        let isSelected: Bool = {
            switch option.selection {
            case .agenda:
                return viewModel.isNextFitAgendaSelected
            case .wod(let modalityId):
                return highlightedNextFitModalityId == modalityId
            }
        }()

        return Button {
            let selection = option.selection
            viewModel.selectedNextFitContent = selection
            if selection != .agenda {
                viewModel.clearNextFitAgendaDetail()
            }
        } label: {
            nextFitContentOptionLabel(option)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected
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
                                : AnyShapeStyle(Color.black.opacity(0.68))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected
                                ? Theme.Colors.primaryGreen.opacity(0.85)
                                : Theme.Colors.primaryGreen.opacity(0.28),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? Theme.Colors.primaryGreen.opacity(0.35) : .clear,
                    radius: 8
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
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if !isTodayAgendaDateSelected, let error = viewModel.nextFitAgendaWodError {
            VStack(alignment: .leading, spacing: 14) {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

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
        .foregroundColor(.white.opacity(0.55))
        .modifier(NextFitCardStyle())
    }

    private func nextFitWodBanner(_ wod: NextFitWodDisplay) -> some View {
        let unitName = viewModel.studentUnitName

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.primaryGreen.opacity(0.16))
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.35), lineWidth: 1)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 2) {
                Text("dashboard.wod.banner_title")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.white)

                if !unitName.isEmpty {
                    Text(verbatim: unitName)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text(verbatim: wod.modalityName.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.Colors.primaryGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6))
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

                LinearGradient(
                    colors: [
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
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
        )
    }

    private func nextFitActivityCard(_ activity: NextFitWodActivityDisplay) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: nextFitActivityIconName(for: activity.title))
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGreen)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 8) {
                Text(activity.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)

                Text(activity.description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Color.black.opacity(0.68)
                Theme.Colors.primaryGreen.opacity(0.05)
            }
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
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
                    .tint(.white)
            } else if let detail = viewModel.selectedNextFitAgendaDetail {
                nextFitAgendaDetailContent(detail)
            } else if let error = viewModel.nextFitAgendaDetailError {
                nextFitAgendaDetailErrorContent(error)
            } else if let error = viewModel.nextFitAgendaError {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                Button {
                    Task { await viewModel.selectNextFitAgendaDate(viewModel.selectedNextFitAgendaDate, locale: locale) }
                } label: {
                    Text("dashboard.try_again_action")
                        .padding(.horizontal, 14)
                        .compactPrimaryGreenActionButton()
                }
                .buttonStyle(.plain)
            } else if viewModel.nextFitAgenda.isEmpty {
                Text("dashboard.no_time_available_for_this_date")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
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
                                        textColor: Theme.Colors.primaryGreen
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
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
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
            .foregroundColor(isSelected ? Theme.Colors.primaryGreen : .white.opacity(0.85))
            .frame(minWidth: 58)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? Theme.Colors.primaryGreen.opacity(0.18)
                            : Color.black.opacity(0.68)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? Theme.Colors.primaryGreen.opacity(0.85)
                            : Theme.Colors.primaryGreen.opacity(0.28),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? Theme.Colors.primaryGreen.opacity(0.35) : .clear,
                radius: 6
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
                Label(LocalizedStringKey("dashboard.back_to_schedule"), systemImage: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
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
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))

            Text("dashboard.participants")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.92))

            if detail.participants.isEmpty {
                Text("dashboard.no_participant_at_this_time")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ForEach(detail.participants) { participant in
                    Text(participant.name)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.92))
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
                Label(LocalizedStringKey("dashboard.back_to_schedule"), systemImage: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
            }
            .buttonStyle(.plain)

            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Button {
                Task { await viewModel.retryNextFitAgendaDetail(locale: locale) }
            } label: {
                Text("dashboard.try_again_action")
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
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
                .foregroundColor(Theme.Colors.primaryGreen)
                .frame(width: 18)
        }
        .font(font)
        .foregroundColor(textColor)
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
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }
                    Text("dashboard.schedule")
                }
                .padding(.horizontal, 14)
                .compactPrimaryGreenActionButton()
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
