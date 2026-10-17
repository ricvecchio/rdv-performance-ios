import SwiftUI

struct StudentDashboardView: View {
    @Binding var path: [AppRoute]
    let studentId: String
    let onSelectSection: (StudentMainSection) -> Void
    let onSelectWorkout: (String, String) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: StudentDashboardViewModel
    @State private var isTeacherLinkIconPulsing = false
    @State private var isRequestLinkSheetPresented = false
    @State private var teacherEmailInput = ""
    @State private var isNextFitLoginSheetPresented = false
    @State private var nextFitEmailInput = ""
    @State private var nextFitPasswordInput = ""

    private let contentMaxWidth: CGFloat = 380
    private let summaryCardHeight: CGFloat = 132

    // Cores locais exclusivas do Tema Claro (padrao da TrainingWeeksView; Tema Escuro usa sempre os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)   // #DDEDDC
        static let innerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255)  // #F0F7EF
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)   // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)       // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)   // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)       // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)        // #C9DFC9
    }

    // Profundidade dos cards: mesma sombra da AdminProfileSelectionView no Tema Claro; Tema Escuro sem sombra
    private var cardShadowColor: Color { appTheme == .light ? .black.opacity(0.25) : .clear }
    private var cardShadowRadius: CGFloat { appTheme == .light ? 10 : 0 }
    private var cardShadowY: CGFloat { appTheme == .light ? 6 : 0 }

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
                    .foregroundStyle(Theme.Colors.ink())
                    // Tema Claro: resolve a cor do título já com o esquema escuro do cabeçalho verde,
                    // sem depender da propagação tardia do `toolbarColorScheme` na primeira exibição.
                    .environment(\.colorScheme, appTheme == .light ? .dark : colorScheme)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
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
                .foregroundStyle(Theme.Colors.ink(0.55))
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
                .tint(Theme.Colors.ink())
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
                    .foregroundColor(appTheme == .light ? Color(red: 0xB7 / 255, green: 0x79 / 255, blue: 0x00 / 255) : .yellow.opacity(0.85)) // Claro: #B77900
                Text("dashboard.notices")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
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
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1))
        .shadow(color: cardShadowColor, radius: cardShadowRadius, y: cardShadowY)
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
                .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.ink(0.55))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.chevron))
        }
        .contentShape(Rectangle())
    }

    private var noLinkedTeacherCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                .scaleEffect(isTeacherLinkIconPulsing ? 1.06 : 0.94)
                .opacity(isTeacherLinkIconPulsing ? 1 : 0.75)
                .animation(
                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                    value: isTeacherLinkIconPulsing
                )

            Text("dashboard.you_do_not_have_a_linked_coach_yet")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

            Text("dashboard.link_with_a_coach_to_receive_workouts_and_track_your_progress")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))

            Button {
                teacherEmailInput = ""
                isRequestLinkSheetPresented = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .appThemeIconForeground()

                    Text("dashboard.invite_coach")
                }
                .padding(.horizontal, 14)
                .modifier(DashboardPrimaryActionButtonModifier(isCompact: true))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1))
        .shadow(color: cardShadowColor, radius: cardShadowRadius, y: cardShadowY)
        .onAppear {
            isTeacherLinkIconPulsing = true
        }
    }

    private var requestLinkSheet: some View {
        ZStack {
            Theme.Colors.sheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Theme.Colors.ink(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("dashboard.request_link")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink())
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("dashboard.enter_the_coach_s_email_to_send_the_request")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.Colors.ink(0.45))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("dashboard.coach_email")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink(0.75))

                                TextField("dashboard.coach_email_placeholder", text: $teacherEmailInput)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Theme.Colors.ink(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                                    )
                                    .foregroundStyle(Theme.Colors.ink(0.92))
                            }

                            if let msg = viewModel.linkActionMessage {
                                Text(msg)
                                    .font(.system(size: 13))
                                    .foregroundColor(viewModel.linkActionMessageIsError ? .yellow.opacity(0.95) : .green.opacity(0.95))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppThemeColor(dark: Color.black.opacity(0.65), light: LightColors.innerSurface))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Color.white.opacity(0.08), light: LightColors.border), lineWidth: 1)
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
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
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
                        .modifier(DashboardPrimaryActionButtonModifier(isCompact: false))
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
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                        .lineLimit(1)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Theme.Colors.ink())
                    } else {
                        Text(weeklyProgressText(completed: completed, total: total))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.ink(0.55))
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
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                }
            }

            if !viewModel.isLoading {
                Spacer(minLength: 0)

                ProgressView(value: progress)
                    .tint(appTheme == .light ? AppThemePalette.lightBar.opacity(0.80) : Theme.Colors.primaryGreen)

                if total == 0 {
                    Text("dashboard.you_do_not_have_workouts_scheduled_for_this_week")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                } else {
                    HStack(spacing: 10) {
                        ForEach(viewModel.currentWeekDaySummaries) { item in
                            VStack(spacing: 6) {
                                Image(systemName: item.isCompleted ? "checkmark.seal.fill" : "circle")
                                    .foregroundStyle(
                                        // Tema Claro: dia concluído em verde militar translúcido (80%); pendente mantém o original
                                        appTheme == .light && item.isCompleted
                                            ? AnyShapeStyle(AppThemePalette.lightBar.opacity(0.80))
                                            : AnyShapeStyle(AppThemeAdaptiveColor(item.isCompleted ? Theme.Colors.primaryGreen : .white.opacity(0.35)))
                                    )
                                Text(weekdayAbbreviation(for: item.date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.Colors.ink(0.75))
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
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1))
        .shadow(color: cardShadowColor, radius: cardShadowRadius, y: cardShadowY)
    }

    private var weeklyProgressIcon: some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach([CGFloat(9), 14, 19], id: \.self) { height in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                    .frame(width: 4, height: height)
            }
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Theme.Colors.ink(0.75))
                .frame(width: 4, height: 11)
        }
        .frame(width: 42, height: 42)
        .background(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.10), light: LightColors.iconSurface))
        .background(Theme.Colors.glass(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
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
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                        .lineLimit(1)

                    if viewModel.isLoadingCurrentWeekCheckIns {
                        ProgressView()
                            .tint(Theme.Colors.ink())
                    } else {
                        Text(weeklyProgressText(completed: completed, total: total))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.ink(0.55))
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
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                }
            }

            if !viewModel.isLoadingCurrentWeekCheckIns {
                Spacer(minLength: 0)

                ProgressView(value: progress)
                    .tint(appTheme == .light ? AppThemePalette.lightBar : Theme.Colors.primaryGreen)

                HStack(spacing: 10) {
                    ForEach(viewModel.currentWeekCheckInSummaries) { item in
                        VStack(spacing: 6) {
                            Image(systemName: item.isCompleted ? "checkmark.seal.fill" : "circle")
                                .foregroundStyle(AppThemeAdaptiveColor(item.isCompleted ? (appTheme == .light ? AppThemePalette.lightBar : Theme.Colors.primaryGreen) : .white.opacity(0.35)))
                            Text(weekdayAbbreviation(for: item.date))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.Colors.ink(0.75))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: summaryCardHeight, maxHeight: summaryCardHeight, alignment: .topLeading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1))
        .shadow(color: cardShadowColor, radius: cardShadowRadius, y: cardShadowY)
    }

    private var weeklyCheckInsIcon: some View {
        Image(systemName: "person.crop.circle.badge.checkmark")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
            .frame(width: 42, height: 42)
            .background(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.10), light: LightColors.iconSurface))
            .background(Theme.Colors.glass(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
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
                            .foregroundStyle(Theme.Colors.icon(Theme.Colors.accentForeground))
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accentForeground)
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
                                .appThemeIconForeground()

                            Text("dashboard.connect_nextfit")
                        }
                        .padding(.horizontal, 14)
                        .modifier(DashboardPrimaryActionButtonModifier(isCompact: true))
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
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: LightColors.iconInk))
                    .frame(width: 42, height: 42)
                    .background(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.10), light: LightColors.iconSurface))
                    .background(Theme.Colors.glass(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("dashboard.wod.title")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink(0.92))
                        .lineLimit(1)

                    if !viewModel.studentUnitName.isEmpty {
                        Text(verbatim: viewModel.studentUnitName)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.ink(0.75))
                            .lineLimit(1)
                    }
                }
                // Tema Claro: textos sobre a foto escurecida usam os valores do esquema escuro (legibilidade)
                .environment(\.colorScheme, appTheme == .light ? .dark : colorScheme)
            }

            Spacer(minLength: 18)

            action()
                // Tema Claro: ação sobre a foto escurecida usa os valores do esquema escuro (legibilidade)
                .environment(\.colorScheme, appTheme == .light ? .dark : colorScheme)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: summaryCardHeight, maxHeight: summaryCardHeight, alignment: .leading)
        .background(
            ZStack {
                if appTheme == .light {
                    // Tema Claro: escurecimento moderado (preto e verde militar das barras) para manter a foto mais viva,
                    // mais intenso à esquerda (textos) e mais leve à direita (detalhes da fotografia)
                    Color.black.opacity(0.15)
                    LinearGradient(
                        colors: [
                            AppThemePalette.lightBar.opacity(0.65),
                            AppThemePalette.lightBar.opacity(0.35),
                            AppThemePalette.lightBar.opacity(0.10)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    AppThemeNeutralGradient(
                        colors: [
                            Color.black.opacity(0.82),
                            Color.black.opacity(0.55),
                            Color.black.opacity(0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                Theme.Colors.primaryGreen.opacity(0.05)
            }
        )
        .background(
            Image("rdv_treino1_horizontal")
                .resizable()
                .scaledToFill()
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: cardShadowColor, radius: cardShadowRadius, y: cardShadowY)
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
            Theme.Colors.sheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Theme.Colors.ink(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("dashboard.sign_in_to_nextfit")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink())
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("common.email")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink(0.75))

                                TextField("dashboard.nextfit.email_placeholder", text: $nextFitEmailInput)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Theme.Colors.ink(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                                    )
                                    .foregroundStyle(Theme.Colors.ink(0.92))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("common.password")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink(0.75))

                                SecureField("dashboard.your_password", text: $nextFitPasswordInput)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Theme.Colors.ink(0.10))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                                    )
                                    .foregroundStyle(Theme.Colors.ink(0.92))
                            }

                            if let error = viewModel.nextFitLoginError {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(.yellow.opacity(0.95))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppThemeColor(dark: Color.black.opacity(0.65), light: LightColors.innerSurface))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Color.white.opacity(0.08), light: LightColors.border), lineWidth: 1)
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
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
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
                        .modifier(DashboardPrimaryActionButtonModifier(isCompact: false))
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

// Botões principais da dashboard (uso exclusivo deste arquivo).
// Escuro: aplica exatamente o estilo original (`primaryGreenActionButton` / `compactPrimaryGreenActionButton`).
// Claro: mesmo formato e dimensões, com fundo verde militar sólido (#29452C), conteúdo claro e sombra.
private struct DashboardPrimaryActionButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    let isCompact: Bool

    func body(content: Content) -> some View {
        if appTheme == .light {
            content
                .font(.system(size: isCompact ? 15 : 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(isEnabled ? 0.92 : 0.55))
                .padding(.vertical, isCompact ? 9 : 14)
                .background(AppThemePalette.lightBar)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isEnabled ? 0.25 : 0.12), radius: 10, y: 6)
                // Conteúdo sobre o verde militar usa os valores claros (ícones, ProgressView)
                .environment(\.colorScheme, .dark)
        } else if isCompact {
            content.compactPrimaryGreenActionButton()
        } else {
            content.primaryGreenActionButton()
        }
    }
}

