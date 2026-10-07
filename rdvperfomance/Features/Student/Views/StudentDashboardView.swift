import SwiftUI

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

    private let contentMaxWidth: CGFloat = 380
    private let summaryCardHeight: CGFloat = 132

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
            Task { await viewModel.load(locale: locale) }
        }
        .task(id: viewModel.hasNextFitSession) {
            await viewModel.loadCurrentWeekCheckIns()
        }
        .sheet(isPresented: $isRequestLinkSheetPresented) {
            requestLinkSheet
                .presentationDetents([.fraction(0.50)])
        }
        .sheet(isPresented: $isNextFitLoginSheetPresented, onDismiss: clearNextFitCredentials) {
            nextFitLoginSheet
                .presentationDetents([.fraction(0.50)])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            DashboardGreeting.styledText(
                name: session.userName,
                audience: .student,
                locale: locale
            )
                .font(.system(size: 26, weight: .bold))
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
            weeklyCheckInsCard
            nextFitWodEntryCard
        case .linked, .failed:
            progressCard
            weeklyCheckInsCard
            nextFitWodEntryCard
        }
    }

    private var noticesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow.opacity(0.85))
                Text("dashboard.notices")
                    .font(.system(size: 17, weight: .bold))
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
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1))
    }

    private var inviteNoticeMessage: String {
        let count = viewModel.pendingTeacherInvites.count
        if count == 1 {
            return AppLocalization.string("dashboard.teacher_invitation.pending_single", locale: locale)
        }

        let format = AppLocalization.string("dashboard.teacher_invitation.pending_multiple", locale: locale)
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
                .font(.system(size: 17, weight: .bold))
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
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1))
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

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                weeklyProgressIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text("dashboard.weekly_progress_title")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(weeklyProgressText(completed: completed, total: total))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if !viewModel.isLoading {
                    Text(
                        String(
                            format: AppLocalization.string("dashboard.progress_percentage", locale: locale),
                            locale: locale,
                            arguments: [Int64((progress * 100).rounded())]
                        )
                    )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
            }

            if !viewModel.isLoading {
                Spacer(minLength: 0)

                ProgressView(value: progress)
                    .tint(Theme.Colors.primaryGreen)

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
        .frame(maxWidth: .infinity, minHeight: summaryCardHeight, maxHeight: summaryCardHeight, alignment: .topLeading)
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1))
    }

    private var weeklyProgressIcon: some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach([CGFloat(9), 14, 19], id: \.self) { height in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.Colors.primaryGreen)
                    .frame(width: 4, height: height)
            }
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.75))
                .frame(width: 4, height: 11)
        }
        .frame(width: 42, height: 42)
        .background(Theme.Colors.primaryGreen.opacity(0.10))
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    private var weeklyCheckInsCard: some View {
        let completed = viewModel.currentWeekCheckInSummaries.filter(\.isCompleted).count
        let total = viewModel.currentWeekCheckInSummaries.count
        let progress = total == 0 ? 0 : Double(completed) / Double(total)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                weeklyCheckInsIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text("dashboard.weekly_checkins_title")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)

                    if viewModel.isLoadingCurrentWeekCheckIns {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(weeklyProgressText(completed: completed, total: total))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if !viewModel.isLoadingCurrentWeekCheckIns {
                    Text(
                        String(
                            format: AppLocalization.string("dashboard.progress_percentage", locale: locale),
                            locale: locale,
                            arguments: [Int64((progress * 100).rounded())]
                        )
                    )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
            }

            if !viewModel.isLoadingCurrentWeekCheckIns {
                Spacer(minLength: 0)

                ProgressView(value: progress)
                    .tint(Theme.Colors.primaryGreen)

                HStack(spacing: 10) {
                    ForEach(viewModel.currentWeekCheckInSummaries) { item in
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
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: summaryCardHeight, maxHeight: summaryCardHeight, alignment: .topLeading)
        .background(Color.black.opacity(0.68))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1))
    }

    private var weeklyCheckInsIcon: some View {
        Image(systemName: "person.crop.circle.badge.checkmark")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Theme.Colors.primaryGreen)
            .frame(width: 42, height: 42)
            .background(Theme.Colors.primaryGreen.opacity(0.10))
            .background(Color.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var nextFitWodEntryCard: some View {
        if viewModel.hasNextFitSession {
            Button {
                path.append(.studentNextFitWod)
            } label: {
                nextFitWodEntryCardContent {
                    HStack(spacing: 6) {
                        Spacer()

                        Text("dashboard.wod.view_details")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
                }
            }
            .buttonStyle(.plain)
        } else {
            nextFitWodEntryCardContent {
                HStack {
                    Spacer()

                    Button {
                        nextFitEmailInput = ""
                        nextFitPasswordInput = ""
                        isNextFitLoginSheetPresented = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "link")

                            Text("dashboard.connect_nextfit")
                        }
                        .padding(.horizontal, 14)
                        .compactPrimaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func nextFitWodEntryCardContent<Action: View>(
        @ViewBuilder action: () -> Action
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
                    .frame(width: 42, height: 42)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("dashboard.wod.title")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)

                    if !viewModel.studentUnitName.isEmpty {
                        Text(verbatim: viewModel.studentUnitName)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 18)

            action()
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: summaryCardHeight, maxHeight: summaryCardHeight, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.82),
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.25)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .background(
            Image("rdv_treino1_horizontal")
                .resizable()
                .scaledToFill()
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }

    private func weeklyProgressText(completed: Int, total: Int) -> String {
        let format = AppLocalization.string("dashboard.weekly_progress", locale: locale)
        return String(
            format: format,
            locale: locale,
            arguments: [Int64(completed), Int64(total)]
        )
    }

    private func weekdayAbbreviation(for date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "").capitalized
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
}
