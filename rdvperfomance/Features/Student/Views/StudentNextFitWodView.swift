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

struct StudentNextFitWodView: View {
    @Binding var path: [AppRoute]
    let studentId: String
    let onSelectSection: (StudentMainSection) -> Void

    @Environment(\.locale) private var locale
    @StateObject private var viewModel: StudentDashboardViewModel
    @State private var isNextFitLogoutConfirmationPresented = false
    @State private var isNextFitLogoutErrorPresented = false

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
                            nextFitWodCard
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

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
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            Task { await viewModel.loadNextFit(locale: locale) }
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

    private var nextFitWodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(nextFitWodTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                if viewModel.hasNextFitSession {
                    Button {
                        isNextFitLogoutConfirmationPresented = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(width: 44, height: 44)
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
            }

            if viewModel.isLoadingNextFitWod {
                ProgressView()
                    .tint(.white)
            } else if viewModel.needsNextFitAuthentication {
                EmptyView()
            } else if let error = viewModel.nextFitError {
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
            } else {
                if viewModel.nextFitContentOptions.count > 1 {
                    Picker("", selection: $viewModel.selectedNextFitContent) {
                        ForEach(viewModel.nextFitContentOptions) { option in
                            nextFitContentOptionLabel(option)
                                .tag(Optional(option.selection))
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.white)
                    .environment(\.colorScheme, .dark)
                    .onChange(of: viewModel.selectedNextFitContent) { _, selection in
                        if selection != .agenda {
                            viewModel.clearNextFitAgendaDetail()
                        }
                    }
                }

                if viewModel.isNextFitAgendaSelected {
                    nextFitAgendaContent
                } else if let wod = viewModel.nextFitWod {
                    VStack(spacing: 10) {
                        ForEach(wod.activities) { activity in
                            VStack(alignment: .leading, spacing: 14) {
                                Text(activity.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primaryGreen)

                                Text(activity.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.92))
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                } else {
                    Text("dashboard.no_wod_available_for_today")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1))
    }

    @ViewBuilder
    private var nextFitAgendaContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            nextFitAgendaDateSelector

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

            nextFitAgendaWodContent
        }
    }

    private var nextFitAgendaDateSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.nextFitAgendaDates, id: \.self) { date in
                    nextFitAgendaDateButton(date: date)
                }
            }
            .padding(.vertical, 1)
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
        let isSelected = Calendar.current.isDate(
            viewModel.selectedNextFitAgendaDate,
            inSameDayAs: date
        )
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "dd/MM"
        return Button {
            Task { await viewModel.selectNextFitAgendaDate(date, locale: locale) }
        } label: {
            Text(verbatim: formatter.string(from: date))
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(isSelected ? Theme.Colors.primaryGreen : .white.opacity(0.65))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    isSelected
                        ? Theme.Colors.primaryGreen.opacity(0.14)
                        : Color.white.opacity(0.04)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected
                                ? Theme.Colors.primaryGreen.opacity(0.55)
                                : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var nextFitAgendaWodContent: some View {
        if viewModel.isLoadingNextFitAgendaWods {
            ProgressView()
                .tint(.white)
        } else if let error = viewModel.nextFitAgendaWodError {
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        } else if let wod = viewModel.nextFitAgendaWod {
            VStack(alignment: .leading, spacing: 10) {
                Text("dashboard.wod_of_the_day")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))

                if viewModel.nextFitAgendaWods.count > 1 {
                    Picker("", selection: $viewModel.selectedNextFitAgendaWodModalityId) {
                        ForEach(viewModel.nextFitAgendaWods) { item in
                            Text(item.modalityName.uppercased()).tag(Optional(item.modalityId))
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.white.opacity(0.06))
                    .overlay(
                        HStack(spacing: 4) {
                            ForEach(viewModel.nextFitAgendaWods) { _ in
                                Capsule()
                                    .stroke(Theme.Colors.primaryGreen.opacity(0.42), lineWidth: 1)
                            }
                        }
                        .padding(2)
                        .allowsHitTesting(false)
                    )
                }

                ForEach(wod.activities) { activity in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(activity.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.primaryGreen)

                        Text(activity.description)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.92))
                            .frame(maxWidth: .infinity, alignment: .leading)
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

    private var nextFitWodTitle: String {
        let unitName = viewModel.studentUnitName
        guard !unitName.isEmpty else {
            return AppLocalization.string("dashboard.wod.title", locale: locale)
        }
        let format = AppLocalization.string("dashboard.wod.title_with_modality", locale: locale)
        return String(format: format, locale: locale, arguments: [unitName])
    }
}
