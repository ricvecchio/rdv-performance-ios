import SwiftUI
import FirebaseFirestore

// Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView.
private let studentTeachersDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

// Tema Claro (habilitado): padrão do botão Sair da ProfileView (verde militar 80%/90% e texto branco),
// mantendo as dimensões dos estilos originais. Tema Escuro e estado desabilitado: estilo original.
private struct StudentTeachersLightBarButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    /// `true`: dimensões do `compactPrimaryGreenActionButton()`; `false`: do `primaryGreenActionButton()`.
    let compact: Bool

    func body(content: Content) -> some View {
        if appTheme == .light && isEnabled {
            content
                .font(.system(size: compact ? 15 : 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, compact ? 9 : 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(studentTeachersDarkGreenBorder, lineWidth: 1)
                )
        } else if compact {
            content
                .compactPrimaryGreenActionButton()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appTheme == .light ? studentTeachersDarkGreenBorder : Color.clear, lineWidth: 1)
                )
        } else {
            content
                .primaryGreenActionButton()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appTheme == .light ? studentTeachersDarkGreenBorder : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct StudentTeachersView: View {

    @Binding var path: [AppRoute]
    let studentEmail: String
    let onSelectSection: (StudentMainSection) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let innerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255) // #F0F7EF (igual à TeacherStudentsListView)
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        static let pendingStatus = Color(red: 0xB7 / 255, green: 0x79 / 255, blue: 0x00 / 255) // #B77900 (mesmo da TeacherStudentsListView)
        static let darkGreenBorder = studentTeachersDarkGreenBorder                               // #294A2F (contorno dos cards e botões)
    }

    private let contentMaxWidth: CGFloat = 380
    private let repository: FirestoreRepository

    @State private var linkedTeachers: [AppUser] = []
    @State private var linkedTeacherIds: Set<String> = []
    @State private var sentRequests: [TeacherStudentLinkRequestFS] = []
    @State private var receivedInvites: [TeacherStudentInviteFS] = []
    @State private var inviteTeachers: [String: AppUser] = [:]
    @State private var isLoadingLinkedTeachers: Bool = false
    @State private var isLoadingData: Bool = false
    @State private var requestPendingCancellation: TeacherStudentLinkRequestFS? = nil
    @State private var invitePendingDecline: TeacherStudentInviteFS? = nil
    @State private var teacherPendingUnlink: AppUser? = nil
    @State private var showRequestCancellationConfirmation: Bool = false
    @State private var showInviteDeclineConfirmation: Bool = false
    @State private var showTeacherUnlinkConfirmation: Bool = false
    @State private var actionErrorMessage: String? = nil
    @State private var selectedTeacher: AppUser? = nil

    @State private var teacherEmailInput: String = ""
    @State private var linkActionMessage: String? = nil
    @State private var linkActionMessageIsError: Bool = false
    @State private var isProcessingLinkAction: Bool = false
    @State private var showRequestLinkModal: Bool = false
    @State private var resolvedStudentEmail: String = ""

    // Abas do corpo da tela (somente apresentação; não afeta carregamento de dados)
    private enum TeachersSection: Hashable {
        case linked
        case sentInvites
        case receivedInvites
    }

    @State private var selectedTeachersSection: TeachersSection = .linked

    init(
        path: Binding<[AppRoute]>,
        studentEmail: String,
        onSelectSection: @escaping (StudentMainSection) -> Void,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.studentEmail = studentEmail
        self.onSelectSection = onSelectSection
        self.repository = repository
        _resolvedStudentEmail = State(
            initialValue: studentEmail
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        )
    }

    private var currentUid: String {
        (session.currentUid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedRouteStudentEmail: String {
        studentEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var effectiveStudentEmail: String {
        normalizedRouteStudentEmail.isEmpty ? resolvedStudentEmail : normalizedRouteStudentEmail
    }

    private var isModalPresented: Bool {
        showRequestLinkModal || selectedTeacher != nil
    }

    var body: some View {
        GeometryReader { viewport in
            ZStack {
            AppThemeBackgroundImage()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        teachersSectionSelector


                        switch selectedTeachersSection {
                        case .linked:
                            linkedTeachersCard
                        case .sentInvites:
                            sentRequestsCard
                        case .receivedInvites:
                            receivedInvitesCard
                        }
                    }
                    .frame(width: min(contentMaxWidth, max(0, viewport.size.width - 32)))
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(width: viewport.size.width, alignment: .center)
                }

                FooterBar(
                    path: $path,
                    kind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: false,
                        isTreinosSelected: false,
                        isRecordsSelected: false,
                        isPerfilSelected: true
                    ),
                    onSelectStudentSection: onSelectSection
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }

            if showRequestLinkModal {
                Theme.Colors.glass(0.25)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
            }
            .frame(width: viewport.size.width, height: viewport.size.height)
        }
        .blur(radius: isModalPresented ? 8 : 0)
        .animation(.easeInOut(duration: 0.20), value: isModalPresented)
        .ignoresSafeArea(.container, edges: [.bottom])
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
                Text("student_teachers.my_coaches")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            // Convidar no cabeçalho (mesmo padrão visual da TeacherStudentsListView); abre o mesmo modal de convite
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    teacherEmailInput = ""
                    linkActionMessage = nil
                    linkActionMessageIsError = false
                    showRequestLinkModal = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                        Text("ui.invite")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
                }
                .buttonStyle(.plain)
                .disabled(isProcessingLinkAction)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
        .sheet(isPresented: $showRequestLinkModal) {
            requestLinkModalView()
                .presentationDetents([.fraction(0.50)])
        }
        .sheet(item: $selectedTeacher) { teacher in
            teacherDetailsSheet(teacher)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationContentInteraction(.scrolls)
        }
        .task(id: "\(currentUid)|\(normalizedRouteStudentEmail)") {
            await loadStudentEmailIfNeeded()
            await refreshData()
        }
        .alert("student_teachers.cancel_invitation_confirmation_title", isPresented: $showRequestCancellationConfirmation) {
            Button("common.cancel", role: .cancel) { requestPendingCancellation = nil }
            Button("student_teachers.confirm_cancellation", role: .destructive) {
                Task { await cancelRequest() }
            }
        } message: {
            Text("student_teachers.do_you_want_to_cancel_this_invitation_sent_to_the_coach")
        }
        .alert("student_teachers.decline_invitation_confirmation_title", isPresented: $showInviteDeclineConfirmation) {
            Button("common.cancel", role: .cancel) { invitePendingDecline = nil }
            Button("student_teachers.decline", role: .destructive) {
                Task { await declineInvite() }
            }
        } message: {
            Text("student_teachers.do_you_want_to_decline_this_link_invitation")
        }
        .alert("student_teachers.decline_link_confirmation_title", isPresented: $showTeacherUnlinkConfirmation) {
            Button("common.cancel", role: .cancel) { teacherPendingUnlink = nil }
            Button("student_teachers.decline_link_action", role: .destructive) {
                Task { await unlinkTeacher() }
            }
        } message: {
            let format = AppLocalization.string("student_teachers.unlink_confirmation", locale: locale)
            Text(
                String(
                    format: format,
                    locale: locale,
                    arguments: [teacherPendingUnlink?.name ?? ""]
                )
            )
        }
        .alert("common.error", isPresented: Binding(
            get: { actionErrorMessage != nil },
            set: { if !$0 { actionErrorMessage = nil } }
        )) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(actionErrorMessage ?? AppLocalization.string("common.unexpected_error", locale: locale))
        }
    }

    // MARK: - Abas (mesmo padrão visual de `studentsSectionSelector` da TeacherStudentsListView)

    private var teachersSectionSelector: some View {
        HStack(spacing: 0) {
            teachersSectionSegmentButton(title: "student_teachers.linked_coaches_tab", section: .linked)
            teachersSectionSegmentButton(title: "student_teachers.sent_invitations_tab", section: .sentInvites)
            teachersSectionSegmentButton(title: "student_teachers.received_invitations_tab", section: .receivedInvites)
        }
        // Mesma altura nos três segmentos, mesmo quando algum título quebra em duas linhas
        .fixedSize(horizontal: false, vertical: true)
        .padding(3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
                // Profundidade apenas no Tema Claro
                .shadow(
                    color: appTheme == .light ? .black.opacity(0.25) : .clear,
                    radius: appTheme == .light ? 10 : 0,
                    y: appTheme == .light ? 6 : 0
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.darkGreenBorder), lineWidth: 1)
        )
    }

    // Segmento: selecionado com preenchimento (verde militar no Tema Claro / verde original no Tema Escuro);
    // não selecionado transparente, sem borda.
    private func teachersSectionSegmentButton(title: LocalizedStringKey, section: TeachersSection) -> some View {
        let isSelected = selectedTeachersSection == section
        let isLightSelected = appTheme == .light && isSelected

        return Button {
            selectedTeachersSection = section
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    isLightSelected
                        ? AnyShapeStyle(Color.white)
                        : AnyShapeStyle(AppThemeColor(dark: Color.white, light: LightColors.primaryText))
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var linkedTeachersCard: some View {
        card(title: "student_teachers.linked_coaches_section", systemImage: "person.2.fill", isCompact: appTheme == .light) {
            if isLoadingData {
                loadingView(AppLocalization.string("student_teachers.loading_teachers", locale: locale))
            } else if linkedTeachers.isEmpty {
                emptyView(
                    title: "student_teachers.no_linked_coach",
                    message: "student_teachers.invite_or_accept_coach"
                )
            } else {
                ForEach(linkedTeachers, id: \.id) { teacher in
                    teacherRow(teacher)
                    if teacher.id != linkedTeachers.last?.id {
                        cardDivider
                    }
                }
            }
        }
    }

    private var sentRequestsCard: some View {
        card(title: "student_teachers.sent_invitations_section", systemImage: "paperplane.fill") {
            if isLoadingData {
                loadingView(AppLocalization.string("student_teachers.loading_invitations", locale: locale))
            } else if sentRequests.isEmpty {
                emptyView(
                    title: "student_teachers.no_sent_invitation",
                    message: "student_teachers.invite_coach_to_start_link"
                )
            } else {
                ForEach(sentRequests, id: \.id) { request in
                    sentRequestRow(request)
                    if request.id != sentRequests.last?.id {
                        cardDivider
                    }
                }
            }
        }
    }

    private var receivedInvitesCard: some View {
        card(title: "student_teachers.received_invitations_section", systemImage: "envelope.open.fill") {
            if isLoadingData {
                loadingView(AppLocalization.string("student_teachers.loading_invitations", locale: locale))
            } else if receivedInvites.isEmpty {
                emptyView(
                    title: "student_teachers.no_pending_invitation",
                    message: "student_teachers.coach_invitations_will_appear_here"
                )
            } else {
                ForEach(receivedInvites, id: \.id) { invite in
                    receivedInviteRow(invite)
                    if invite.id != receivedInvites.last?.id {
                        cardDivider
                    }
                }
            }
        }
    }

    private func card<Content: View>(title: LocalizedStringKey, systemImage: String, isCompact: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink(0.35))

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.top, isCompact ? 8 : 14)
            .padding(.bottom, isCompact ? 2 : 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            content()
            Color.clear.frame(height: isCompact ? 4 : 8)
        }
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.darkGreenBorder), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func teacherRow(_ teacher: AppUser) -> some View {
        HStack(spacing: 0) {
            Button {
                selectedTeacher = teacher
            } label: {
                HStack(spacing: 14) {
                    UserAvatarView(base64: teacher.photoBase64, size: 28)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(teacher.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(teacher.email)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.ink(0.35))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(role: .destructive) {
                    teacherPendingUnlink = teacher
                    showTeacherUnlinkConfirmation = true
                } label: {
                    Label(LocalizedStringKey("student_teachers.decline_link_action"), systemImage: "person.badge.minus")
                }
            } label: {
                menuIcon
            }
            .buttonStyle(.plain)
            .fixedSize()
            .disabled(isProcessingLinkAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, appTheme == .light ? 6 : 14)
        .frame(maxWidth: .infinity)
    }

    private func sentRequestRow(_ request: TeacherStudentLinkRequestFS) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                // Tema Claro: mesmo laranja do status Pendente da TeacherStudentsListView (#B77900)
                .foregroundColor(appTheme == .light ? LightColors.pendingStatus : .yellow.opacity(0.75))
                .font(.system(size: 15))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(request.teacherEmail)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                    .lineLimit(1)
                    .truncationMode(.tail)
                pendingStatus
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(role: .destructive) {
                    requestPendingCancellation = request
                    showRequestCancellationConfirmation = true
                } label: {
                    Label(LocalizedStringKey("student_teachers.cancel_invitation_action"), systemImage: "xmark.circle")
                }
            } label: {
                menuIcon
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private func receivedInviteRow(_ invite: TeacherStudentInviteFS) -> some View {
        let teacher = inviteTeachers[invite.teacherId]

        return HStack(spacing: 0) {
            Button {
                openTeacherDetails(teacher)
            } label: {
                HStack(spacing: 14) {
                    UserAvatarView(base64: teacher?.photoBase64, size: 28)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(teacher?.name ?? invite.teacherEmail)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(invite.teacherEmail)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.ink(0.35))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button {
                    Task { await acceptInvite(invite) }
                } label: {
                    Label(LocalizedStringKey("student_teachers.accept_link"), systemImage: "checkmark")
                }
                Button(role: .destructive) {
                    invitePendingDecline = invite
                    showInviteDeclineConfirmation = true
                } label: {
                    Label(LocalizedStringKey("student_teachers.decline_invitation_action"), systemImage: "xmark.circle")
                }
            } label: {
                menuIcon
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    private func openTeacherDetails(_ teacher: AppUser?) {
        guard let teacher else {
            actionErrorMessage = AppLocalization.string("student_teachers.teacher_data_load_error", locale: locale)
            return
        }
        selectedTeacher = teacher
    }

    private func teacherDetailsSheet(_ teacher: AppUser) -> some View {
        let title = AppLocalization.string("common.trainer", locale: locale)
        return ZStack {
            Theme.Colors.sheetBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 10) {
                        Text(title)
                            .font(Theme.Fonts.headerTitle())
                            .foregroundStyle(Theme.Colors.ink())

                        UserAvatarView(base64: teacher.photoBase64, size: 72)

                        Text(teacher.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.92))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    if teacherHasDetails(teacher) {
                        VStack(alignment: .leading, spacing: 14) {
                            teacherDetailsField(title: AppLocalization.string("student_teachers.cref", locale: locale), value: teacher.cref)
                            teacherDetailsField(title: AppLocalization.string("student_teachers.biography", locale: locale), value: teacher.bio)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Color.clear, light: LightColors.darkGreenBorder), lineWidth: 1)
                        )
                    }

                    Button("common.close") {
                        selectedTeacher = nil
                    }
                    .padding(.horizontal, 14)
                    .primaryGreenActionButton()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppThemeColor(dark: Color.clear, light: LightColors.darkGreenBorder), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
    }

    private func teacherHasDetails(_ teacher: AppUser) -> Bool {
        [teacher.cref, teacher.bio].contains {
            !($0?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
        }
    }

    @ViewBuilder
    private func teacherDetailsField(title: String, value: String?) -> some View {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedValue.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                Text(trimmedValue)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Colors.ink(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var pendingStatus: some View {
        Text("student_teachers.pending")
            .font(.system(size: 12, weight: .semibold))
            // Tema Claro: #B77900 (TeacherStudentsListView). Tema Escuro: amarelo original.
            .foregroundColor(appTheme == .light ? LightColors.pendingStatus : .yellow.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.yellow.opacity(0.12)))
    }

    private var menuIcon: some View {
        Image(systemName: "ellipsis")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Theme.Colors.icon(Theme.Colors.ink(0.55)))
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
    }

    private var cardDivider: some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.horizontal, 16)
    }

    private func loadingView(_ text: String) -> some View {
        VStack(spacing: 10) {
            ProgressView()
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func emptyView(title: LocalizedStringKey, message: LocalizedStringKey) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink(0.92))
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func requestLinkModalView() -> some View {
        ZStack {
            Theme.Colors.sheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Theme.Colors.ink(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("dashboard.invite_coach")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink())
                            .padding(.top, 4)

                        // Tema Claro: card no padrão do modal "Selecione a categoria do vínculo" (TeacherStudentsListView):
                        // fundo #F0F7EF, borda #294A2F e textos escuros. Tema Escuro: valores originais.
                        VStack(alignment: .leading, spacing: 14) {
                            Text("dashboard.enter_the_coach_s_email_to_send_the_request")
                                .font(.system(size: 13))
                                .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.45).dark, light: LightColors.primaryText.opacity(0.75)))

                            VStack(alignment: .leading, spacing: 8) {
                                Text("dashboard.coach_email")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.75).dark, light: LightColors.primaryText))

                                TextField("dashboard.coach_email_placeholder", text: $teacherEmailInput)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: Theme.Colors.ink(0.10).light))
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: LightColors.darkGreenBorder), lineWidth: 1)
                                    )
                                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.92).dark, light: LightColors.primaryText))
                            }

                            if let message = linkActionMessage {
                                Text(message)
                                    .font(.system(size: 13))
                                    .foregroundColor(
                                        linkActionMessageIsError
                                            ? (appTheme == .light ? LightColors.pendingStatus : .yellow.opacity(0.95))
                                            : (appTheme == .light ? LightColors.darkGreenBorder : .green.opacity(0.95))
                                    )
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppThemeColor(dark: Theme.Colors.cardBackground.dark, light: LightColors.innerSurface))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Theme.Colors.ink(0.08).dark, light: LightColors.darkGreenBorder), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        showRequestLinkModal = false
                    } label: {
                        Text("student_teachers.back")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: LightColors.darkGreenBorder), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessingLinkAction)

                    Button {
                        Task {
                            let didSend = await requestLinkByTeacherEmail(teacherEmail: teacherEmailInput)
                            if didSend {
                                showRequestLinkModal = false
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("dashboard.send_request")

                            if isProcessingLinkAction {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .modifier(StudentTeachersLightBarButtonModifier(compact: false))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessingLinkAction)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
    }

    private func loadStudentEmailIfNeeded() async {
        guard normalizedRouteStudentEmail.isEmpty else {
            resolvedStudentEmail = normalizedRouteStudentEmail
            return
        }

        let uid = currentUid
        guard !uid.isEmpty else {
            resolvedStudentEmail = ""
            return
        }

        do {
            let user = try await repository.getUser(uid: uid)
            resolvedStudentEmail = user?.email
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
        } catch {
            resolvedStudentEmail = ""
        }
    }

    private func loadLinkedTeachers() async {
        let uid = currentUid
        guard !uid.isEmpty else {
            linkedTeachers = []
            linkedTeacherIds = []
            return
        }

        isLoadingLinkedTeachers = true
        defer { isLoadingLinkedTeachers = false }

        var teacherIds: [String] = []

        do {
            let relations = try await repository.getTeacherLinksForStudent(studentId: uid)
            teacherIds = Array(
                Set(
                    relations
                        .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                )
            )
        } catch {
            teacherIds = []
        }

        linkedTeacherIds = Set(teacherIds)

        guard !teacherIds.isEmpty else {
            linkedTeachers = []
            return
        }

        let repo = repository
        var result: [AppUser] = []

        await withTaskGroup(of: AppUser?.self) { group in
            for teacherId in teacherIds {
                group.addTask {
                    do {
                        return try await repo.getUser(uid: teacherId)
                    } catch {
                        return nil
                    }
                }
            }

            for await user in group {
                if let user {
                    result.append(user)
                }
            }
        }

        result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        linkedTeachers = result
    }

    private func refreshData() async {
        let uid = currentUid
        guard !uid.isEmpty else {
            linkedTeachers = []
            linkedTeacherIds = []
            sentRequests = []
            receivedInvites = []
            inviteTeachers = [:]
            return
        }

        isLoadingData = true
        defer { isLoadingData = false }
        await loadLinkedTeachers()

        do {
            async let requests = repository.getRequestsForStudent(studentId: uid)
            let allInvites: [TeacherStudentInviteFS]
            if effectiveStudentEmail.isEmpty {
                allInvites = []
            } else {
                allInvites = try await repository.getInvitesForStudent(studentEmail: effectiveStudentEmail)
            }
            let allRequests = try await requests

            sentRequests = allRequests.filter {
                let teacherId = $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return status == "pending" && !linkedTeacherIds.contains(teacherId)
            }
            receivedInvites = allInvites.filter {
                let teacherId = $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return status == "pending" && !linkedTeacherIds.contains(teacherId)
            }

            let teacherIds = Array(
                Set(
                    receivedInvites
                        .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                )
            )
            inviteTeachers = try await repository.getUsers(byIds: teacherIds)
        } catch {
            sentRequests = []
            receivedInvites = []
            inviteTeachers = [:]
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func cancelRequest() async {
        guard let request = requestPendingCancellation,
              let requestId = request.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !requestId.isEmpty else {
            requestPendingCancellation = nil
            actionErrorMessage = AppLocalization.string("student_teachers.invite_identifier_missing", locale: locale)
            return
        }

        do {
            try await repository.cancelLinkRequest(requestId: requestId)
            requestPendingCancellation = nil
            await refreshData()
        } catch {
            requestPendingCancellation = nil
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func acceptInvite(_ invite: TeacherStudentInviteFS) async {
        let uid = currentUid
        guard !uid.isEmpty else {
            actionErrorMessage = AppLocalization.string("student_teachers.student_identifier_missing", locale: locale)
            return
        }

        do {
            try await repository.acceptInvite(invite: invite, studentId: uid)
            await refreshData()
        } catch {
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func declineInvite() async {
        guard let invite = invitePendingDecline else {
            return
        }

        do {
            try await repository.declineInvite(invite: invite)
            invitePendingDecline = nil
            await refreshData()
        } catch {
            invitePendingDecline = nil
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func unlinkTeacher() async {
        showTeacherUnlinkConfirmation = false
        guard let teacher = teacherPendingUnlink,
              let teacherId = teacher.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !teacherId.isEmpty else {
            teacherPendingUnlink = nil
            actionErrorMessage = AppLocalization.string("student_teachers.teacher_identifier_missing", locale: locale)
            return
        }

        let studentId = currentUid
        guard !studentId.isEmpty else {
            teacherPendingUnlink = nil
            actionErrorMessage = AppLocalization.string("student_teachers.student_identifier_missing", locale: locale)
            return
        }

        isProcessingLinkAction = true
        defer { isProcessingLinkAction = false }

        do {
            try await repository.unlinkStudentCompletelyFromTeacher(
                teacherId: teacherId,
                studentId: studentId
            )
            teacherPendingUnlink = nil
            await refreshData()
        } catch {
            teacherPendingUnlink = nil
            actionErrorMessage = (error as NSError).localizedDescription
        }
    }

    private func requestLinkByTeacherEmail(teacherEmail: String) async -> Bool {
        let email = teacherEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard email.contains("@"), email.contains(".") else {
            linkActionMessage = localizedLinkActionMessage(
                key: "student_teachers.link_request.invalid_email",
                value: AppLocalization.string(
                    "student_teachers.link_request.invalid_email",
                    locale: locale
                )
            )
            linkActionMessageIsError = true
            return false
        }

        let uid = currentUid
        guard !uid.isEmpty else {
            linkActionMessage = AppLocalization.string("student_teachers.student_identifier_missing", locale: locale)
            linkActionMessageIsError = true
            return false
        }

        await loadStudentEmailIfNeeded()
        let currentStudentEmail = effectiveStudentEmail
        if currentStudentEmail.isEmpty {
            linkActionMessage = AppLocalization.string(
                "student_teachers.link_request.student_email_missing",
                locale: locale
            )
            linkActionMessageIsError = true
            return false
        }

        isProcessingLinkAction = true
        linkActionMessage = nil
        linkActionMessageIsError = false
        defer { isProcessingLinkAction = false }

        do {
            guard let teacher = try await repository.getTeacherByEmail(email: email),
                  let teacherIdRaw = teacher.id else {
                linkActionMessage = localizedLinkActionMessage(
                    key: "student_teachers.link_request.teacher_not_found",
                    value: AppLocalization.string(
                        "student_teachers.link_request.teacher_not_found",
                        locale: locale
                    )
                )
                linkActionMessageIsError = true
                return false
            }

            let teacherId = teacherIdRaw.trimmingCharacters(in: .whitespacesAndNewlines)
            if teacherId.isEmpty {
                linkActionMessage = AppLocalization.string("student_teachers.teacher_identifier_missing", locale: locale)
                linkActionMessageIsError = true
                return false
            }

            await loadLinkedTeachers()

            if linkedTeacherIds.contains(teacherId) {
                linkActionMessage = AppLocalization.string(
                    "student_teachers.link_request.already_linked",
                    locale: locale
                )
                linkActionMessageIsError = true
                return false
            }

            do {
                let requests = try await repository.getRequestsForStudent(studentId: uid)
                let hasPendingSameTeacher = requests.contains { request in
                    let requestTeacherId = request.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                    let status = request.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    return requestTeacherId == teacherId && status == "pending"
                }
                if hasPendingSameTeacher {
                    linkActionMessage = localizedLinkActionMessage(
                        key: "student_teachers.link_request.pending",
                        value: AppLocalization.string(
                            "student_teachers.link_request.pending",
                            locale: locale
                        )
                    )
                    linkActionMessageIsError = true
                    return false
                }
            } catch {
            }

            try await repository.createLinkRequest(
                studentId: uid,
                studentEmail: currentStudentEmail,
                teacherId: teacherId,
                teacherEmail: email
            )

            linkActionMessage = localizedLinkActionMessage(
                key: "student_teachers.link_request.success",
                value: AppLocalization.string(
                    "student_teachers.link_request.success",
                    locale: locale
                )
            )
            linkActionMessageIsError = false

            await refreshData()
            return true
        } catch {
            let nsError = error as NSError
            if nsError.domain == FirestoreErrorDomain,
               nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
                linkActionMessage = AppLocalization.string(
                    "student_teachers.link_request.permission_denied",
                    locale: locale
                )
                linkActionMessageIsError = true
                return false
            }

            linkActionMessage = nsError.localizedDescription
            linkActionMessageIsError = true
            return false
        }
    }

    private func localizedLinkActionMessage(key: String, value: String) -> String {
        return value
    }
}
