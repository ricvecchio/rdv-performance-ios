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

struct StudentDashboardView: View {
    @Binding var path: [AppRoute]
    let studentId: String
    let onSelectSection: (StudentMainSection) -> Void
    let onSelectWorkout: (String, String) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @StateObject private var viewModel: StudentDashboardViewModel
    @State private var isTeacherLinkIconPulsing = false
    @State private var isRequestLinkSheetPresented = false
    @State private var teacherEmailInput = ""
    @State private var isNextFitLoginSheetPresented = false
    @State private var nextFitEmailInput = ""
    @State private var nextFitPasswordInput = ""
    @State private var isNextFitLogoutConfirmationPresented = false
    @State private var isNextFitLogoutErrorPresented = false

    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        studentId: String,
        onSelectSection: @escaping (StudentMainSection) -> Void,
        onSelectWorkout: @escaping (String, String) -> Void = { _, _ in },
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentId = studentId
        self.onSelectSection = onSelectSection
        self.onSelectWorkout = onSelectWorkout
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
                            header
                            dashboardContent
                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                FooterBar(
                    path: $path,
                    kind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: true,
                        isTreinosSelected: false,
                        isRecordsSelected: false,
                        isPerfilSelected: false
                    ),
                    onSelectStudentSection: onSelectSection
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("dashboard.student_area")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            logLocalizationSnapshot()
            Task { await viewModel.load(locale: locale) }
        }
        .onChange(of: locale.identifier) { _, _ in
            logLocalizationSnapshot()
        }
        .sheet(isPresented: $isRequestLinkSheetPresented) {
            requestLinkSheet
                .presentationDetents([.fraction(0.50)])
        }
        .sheet(isPresented: $isNextFitLoginSheetPresented, onDismiss: clearNextFitCredentials) {
            nextFitLoginSheet
                .presentationDetents([.fraction(0.50)])
        }
        .alert("dashboard.could_not_disconnect_from_nextfit", isPresented: $isNextFitLogoutErrorPresented) {
            Button("common.ok", role: .cancel) { }
        } message: {
            Text("dashboard.try_again_message")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            Text("dashboard.discipline_today_results_tomorrow")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var dashboardContent: some View {
        if !viewModel.pendingTeacherInvites.isEmpty {
            noticesCard
        }

        switch viewModel.teacherLinkState {
        case .loading:
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        case .unlinked:
            noLinkedTeacherCard
            if viewModel.isMuralhaStudent {
                nextFitWodCard
            }
        case .linked, .failed:
            progressCard
            if viewModel.isMuralhaStudent {
                nextFitWodCard
            } else {
                upcomingWorkoutsCard
            }
        }
    }

    private var noticesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow.opacity(0.85))
                Text("dashboard.notices")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
            }

            Button {
                path.append(.studentTeachers(
                    studentEmail: viewModel.pendingTeacherInvites[0].studentEmail
                ))
            } label: {
                noticeRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "dashboard.teacher_invitation.title",
                    message: inviteNoticeMessage
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var inviteNoticeMessage: String {
        let count = viewModel.pendingTeacherInvites.count
        if count == 1 {
            return String(localized: "dashboard.teacher_invitation.pending_single", locale: locale)
        }

        let format = String(localized: "dashboard.teacher_invitation.pending_multiple", locale: locale)
        return String(format: format, locale: locale, arguments: [Int64(count)])
    }

    private func noticeRow(
        icon: String,
        title: LocalizedStringKey,
        message: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Theme.Colors.primaryGreen)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .contentShape(Rectangle())
    }

    private var noLinkedTeacherCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(Theme.Colors.primaryGreen)
                .scaleEffect(isTeacherLinkIconPulsing ? 1.06 : 0.94)
                .opacity(isTeacherLinkIconPulsing ? 1 : 0.75)
                .animation(
                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                    value: isTeacherLinkIconPulsing
                )

            Text("dashboard.you_do_not_have_a_linked_coach_yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.92))

            Text("dashboard.link_with_a_coach_to_receive_workouts_and_track_your_progress")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Button {
                teacherEmailInput = ""
                isRequestLinkSheetPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")

                    Text("dashboard.invite_coach")
                }
                .padding(.horizontal, 14)
                .compactPrimaryGreenActionButton()
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .onAppear {
            isTeacherLinkIconPulsing = true
        }
    }

    private var requestLinkSheet: some View {
        ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("dashboard.request_link")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("dashboard.enter_the_coach_s_email_to_send_the_request")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.45))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("dashboard.coach_email")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))

                                TextField("dashboard.coach_email_placeholder", text: $teacherEmailInput)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                                    .foregroundColor(.white.opacity(0.92))
                            }

                            if let msg = viewModel.linkActionMessage {
                                Text(msg)
                                    .font(.system(size: 13))
                                    .foregroundColor(viewModel.linkActionMessageIsError ? .yellow.opacity(0.95) : .green.opacity(0.95))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        isRequestLinkSheetPresented = false
                    } label: {
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isProcessingLinkAction)

                    Button {
                        Task {
                            let ok = await viewModel.requestLinkByTeacherEmail(
                                teacherEmail: teacherEmailInput,
                                locale: locale
                            )
                            if ok {
                                isRequestLinkSheetPresented = false
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("dashboard.send_request")

                            if viewModel.isProcessingLinkAction {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isProcessingLinkAction)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
    }

    private var progressCard: some View {
        let completed = viewModel.currentWeekDaySummaries.filter(\.isCompleted).count
        let total = viewModel.currentWeekDaySummaries.count
        let progress = total == 0 ? 0 : Double(completed) / Double(total)

        return VStack(alignment: .leading, spacing: 14) {
            Text("dashboard.weekly_progress_title")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.92))
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(weeklyProgressText(completed: completed, total: total))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                HStack(spacing: 10) {
                    ProgressView(value: progress)
                        .tint(Theme.Colors.primaryGreen)
                    Text(
                        String(
                            format: String(localized: "dashboard.progress_percentage", locale: locale),
                            locale: locale,
                            arguments: [Int64((progress * 100).rounded())]
                        )
                    )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
                if total == 0 {
                    Text("dashboard.you_do_not_have_workouts_scheduled_for_this_week")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                } else {
                    HStack(spacing: 10) {
                        ForEach(viewModel.currentWeekDaySummaries) { item in
                            VStack(spacing: 6) {
                                Image(systemName: item.isCompleted ? "checkmark.seal.fill" : "circle")
                                    .foregroundColor(item.isCompleted ? Theme.Colors.primaryGreen : .white.opacity(0.35))
                                Text(weekdayAbbreviation(for: item.date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var nextFitWodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(nextFitWodTitle)
                    .font(.system(size: 18, weight: .bold))
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
                Text("dashboard.connect_your_nextfit_account_to_view_today_s_workout")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                Button {
                    nextFitEmailInput = ""
                    nextFitPasswordInput = ""
                    isNextFitLoginSheetPresented = true
                } label: {
                    ZStack(alignment: .leading) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")

                            Text("dashboard.invite_coach")
                        }
                        .hidden()

                        HStack(spacing: 10) {
                            Image(systemName: "link")

                            Text("dashboard.connect_nextfit")
                        }
                    }
                    .padding(.horizontal, 14)
                    .compactPrimaryGreenActionButton()
                }
                .buttonStyle(.plain)
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
                    .tint(Color.white.opacity(0.06))
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
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
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
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }

            if viewModel.isTomorrowAgendaSelected {
                nextFitAgendaWodContent
            }
        }
    }

    private var nextFitAgendaDateSelector: some View {
        HStack(spacing: 10) {
            nextFitAgendaDateButton(
                day: .today,
                date: viewModel.todayAgendaDate
            )
            nextFitAgendaDateButton(
                day: .tomorrow,
                date: viewModel.tomorrowAgendaDate
            )
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

    private func nextFitAgendaDateButton(day: DashboardAgendaDay, date: Date) -> some View {
        let isSelected = Calendar.current.isDate(
            viewModel.selectedNextFitAgendaDate,
            inSameDayAs: date
        )
        let title = day.title(locale: locale)
        return Button {
            Task { await viewModel.selectNextFitAgendaDate(date, locale: locale) }
        } label: {
            Text(
                String(
                    format: String(localized: "dashboard.agenda.date_label", locale: locale),
                    locale: locale,
                    arguments: [
                        title,
                        date.formatted(.dateTime.day().month(.twoDigits).locale(locale))
                    ]
                )
            )
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? Theme.Colors.primaryGreen : .white.opacity(0.65))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(isSelected ? Color.white.opacity(0.10) : Color.white.opacity(0.04))
                .cornerRadius(10)
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
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
            return String(localized: "dashboard.wod.title", locale: locale)
        }
        let format = String(localized: "dashboard.wod.title_with_modality", locale: locale)
        return String(format: format, locale: locale, arguments: [unitName])
    }

    private var upcomingWorkoutsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("dashboard.upcoming_workouts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
                Button("dashboard.view_all") {
                    onSelectSection(.agenda)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryGreen)
                .buttonStyle(.plain)
            }

            if viewModel.isLoading {
                ProgressView().tint(.white)
            } else if viewModel.upcomingDayGroups.isEmpty {
                Text("dashboard.no_workout_scheduled")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ForEach(Array(viewModel.upcomingDayGroups.enumerated()), id: \.element.id) { index, item in
                    Button {
                        guard let dayId = item.initialDayId else { return }
                        onSelectWorkout(item.weekId, dayId)
                    } label: {
                        upcomingWorkoutRow(item)
                    }
                    .buttonStyle(.plain)
                    if index < viewModel.upcomingDayGroups.count - 1 {
                        Divider().background(Theme.Colors.divider).padding(.leading, 42)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var nextFitLoginSheet: some View {
        ZStack {
            Theme.Colors.headerBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("dashboard.sign_in_to_nextfit")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("common.email")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))

                                TextField("dashboard.nextfit.email_placeholder", text: $nextFitEmailInput)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                                    .foregroundColor(.white.opacity(0.92))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("common.password")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.75))

                                SecureField("dashboard.your_password", text: $nextFitPasswordInput)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                                    .foregroundColor(.white.opacity(0.92))
                            }

                            if let error = viewModel.nextFitLoginError {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.yellow.opacity(0.95))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        isNextFitLoginSheetPresented = false
                    } label: {
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isAuthenticatingNextFit)

                    Button {
                        let email = nextFitEmailInput
                        let password = nextFitPasswordInput
                        nextFitPasswordInput = ""

                        Task {
                            if await viewModel.authenticateNextFit(email: email, password: password, locale: locale) {
                                isNextFitLoginSheetPresented = false
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("dashboard.sign_in")

                            if viewModel.isAuthenticatingNextFit {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isAuthenticatingNextFit)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
    }

    private func clearNextFitCredentials() {
        nextFitEmailInput = ""
        nextFitPasswordInput = ""
    }

    private func upcomingWorkoutRow(_ item: StudentDashboardDayGroup) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundColor(.green.opacity(0.85))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(dateTitle(for: item.date))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                    Spacer()
                    Text(
                        String(
                            format: String(localized: "dashboard.progress_percentage", locale: locale),
                            locale: locale,
                            arguments: [Int64((item.progress * 100).rounded())]
                        )
                    )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.primaryGreen)
                }
                let completionFormat = item.totalCount == 1
                    ? String(localized: "dashboard.upcoming_workouts.progress_singular", locale: locale)
                    : String(localized: "dashboard.upcoming_workouts.progress_plural", locale: locale)
                Text(
                    String(
                        format: completionFormat,
                        locale: locale,
                        arguments: [Int64(item.completedCount), Int64(item.totalCount)]
                    )
                )
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                ProgressView(value: item.progress)
                    .tint(Theme.Colors.primaryGreen)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
                .padding(.top, 3)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var greeting: String {
        DashboardGreeting.text(
            name: session.userName,
            audience: .student,
            locale: locale
        )
    }

    private func weeklyProgressText(completed: Int, total: Int) -> String {
        let format = String(localized: "dashboard.weekly_progress", locale: locale)
        let value = String(
            format: format,
            locale: locale,
            arguments: [Int64(completed), Int64(total)]
        )
        LocalizationDiagnostics.resolved(
            context: "StudentDashboard.weeklyProgress",
            locale: locale,
            key: "dashboard.weekly_progress",
            value: value
        )
        return value
    }

    private func logLocalizationSnapshot() {
        let completed = viewModel.currentWeekDaySummaries.filter(\.isCompleted).count
        let total = viewModel.currentWeekDaySummaries.count
        LocalizationDiagnostics.catalogAvailability(locale: locale)
        _ = greeting
        _ = weeklyProgressText(completed: completed, total: total)
        _ = DashboardAgendaDay.today.title(locale: locale)
        _ = DashboardAgendaDay.tomorrow.title(locale: locale)
    }

    private func weekdayAbbreviation(for date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
    }

    private func dateTitle(for date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEddMM")
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }
}
