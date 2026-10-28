// TeacherStudentsListView.swift — Lista de alunos do professor com filtros e ações de desvincular
import SwiftUI
import Combine

struct TeacherStudentsListView: View {

    @Binding var path: [AppRoute]
    let selectedCategory: TreinoTipo
    let initialFilter: TreinoTipo?
    let onBack: () -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme
    // Usado apenas para manter o esquema atual do seletor de abas do convite fora do Tema Claro
    @Environment(\.colorScheme) private var colorScheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let innerSurface = Color(red: 0xF0 / 255, green: 0xF7 / 255, blue: 0xEF / 255) // #F0F7EF
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)  // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)      // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        // Ícone e texto do status Pendente (laranja mostarda)
        static let pendingStatus = Color(red: 0xB7 / 255, green: 0x79 / 255, blue: 0x00 / 255) // #B77900
    }
    @StateObject private var vm: TeacherStudentsListViewModel

    @State private var filter: TreinoTipo? = nil
    private let contentMaxWidth: CGFloat = 380

    @State private var studentPendingCategoryChange: AppUser? = nil
    @State private var showCategoryChangeDialog: Bool = false
    @State private var selectedCategoryChangeCategories: Set<TreinoTipo> = []

    // Modal convite
    @State private var showInviteSheet: Bool = false
    @State private var inviteEmail: String = ""

    // ✅ Cancelamento de convite pendente na lista principal
    @State private var invitePendingCancel: TeacherStudentInviteFS? = nil
    @State private var showCancelInviteConfirm: Bool = false

    @State private var studentPendingLink: StudentLinkItem? = nil
    @State private var showCategoryDialog: Bool = false
    @State private var selectedLinkCategories: Set<TreinoTipo> = []

    @State private var linkRequestPendingDecline: StudentLinkItem? = nil
    @State private var showDeclineLinkRequestConfirm: Bool = false

    // Abas do corpo da tela (somente apresentação; não afeta carregamento de dados)
    private enum StudentsSection: Hashable {
        case linked
        case sentInvites
        case receivedInvites
    }

    @State private var selectedStudentsSection: StudentsSection = .linked

    init(
        path: Binding<[AppRoute]>,
        selectedCategory: TreinoTipo,
        initialFilter: TreinoTipo?,
        onBack: @escaping () -> Void,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.selectedCategory = selectedCategory
        self.initialFilter = initialFilter
        self.onBack = onBack
        _vm = StateObject(wrappedValue: TeacherStudentsListViewModel(repository: repository))
    }

    var body: some View {
        mainContent
        .blur(radius: isAnySheetPresented ? 8 : 0)
        .animation(.easeInOut(duration: 0.18), value: isAnySheetPresented)

        .onAppear {
            filter = initialFilter
            guard vm.hasLoadedStudents,
                  let teacherId = session.uid,
                  !teacherId.isEmpty else {
                return
            }
            Task { await vm.loadStudents(teacherId: teacherId, force: true) }
        }
        .onChange(of: path) { _, newPath in
            guard let teacherId = session.uid, !teacherId.isEmpty else { return }
            if case .some(.teacherStudentDetail) = newPath.last { return }
            Task { await vm.loadStudents(teacherId: teacherId, force: true) }
        }
        // Carrega alunos e convites pendentes assim que session.uid estiver disponível
        .task(id: session.uid ?? "") {
            await loadInitialData()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
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
                Text("common.students")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            // ✅ NOVO: botão Convidar + avatar
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {

                    Button {
                        inviteEmail = ""
                        showInviteSheet = true
                        Task { await loadInvitesIfPossible() }
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

                    HeaderAvatarView(size: 38)
                }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
        .navigationBarTitleDisplayMode(.inline)
        // ✅ Cancelamento de convite pendente com confirmação
        .alert("ui.cancel_invitation_2", isPresented: $showCancelInviteConfirm) {
            Button("common.cancel", role: .cancel) { invitePendingCancel = nil }
            Button("ui.confirm_cancellation", role: .destructive) {
                Task { await confirmCancelInvite() }
            }
        } message: {
            if let inv = invitePendingCancel {
                Text(
                    String(
                        format: AppLocalization.string(
                            "ui.invitation_to_value_will_be_cancelled",
                            locale: locale
                        ),
                        locale: locale,
                        arguments: [inv.studentEmail]
                    )
                )
            } else {
                Text("ui.the_invitation_will_be_canceled")
            }
        }
        .alert("ui.decline_invitation_2", isPresented: $showDeclineLinkRequestConfirm) {
            Button("common.cancel", role: .cancel) { linkRequestPendingDecline = nil }
            Button("ui.decline", role: .destructive) {
                Task { await confirmDeclineLinkRequest() }
            }
        } message: {
            Text("ui.do_you_want_to_decline_this_link_request")
        }
        .alert("common.error", isPresented: $vm.showLinkErrorAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(vm.linkErrorMessage ?? AppLocalization.string("common.unexpected_error", locale: locale))
        }
        .alert("ui.success", isPresented: $vm.showLinkSuccessAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(vm.linkSuccessMessage ?? AppLocalization.string("ui.student_linked", locale: locale))
        }
        .sheet(isPresented: $showCategoryDialog, onDismiss: {
            studentPendingLink = nil
            selectedLinkCategories = []
        }) {
            CategoryMultiSelectionSheet(
                selectedCategories: $selectedLinkCategories,
                isSaving: vm.isLinkRequestsLoading,
                onCancel: {
                    showCategoryDialog = false
                },
                onSave: {
                    Task { await confirmLink(selectedLinkCategories) }
                }
            )
        }
        .sheet(isPresented: $showCategoryChangeDialog, onDismiss: {
            studentPendingCategoryChange = nil
            selectedCategoryChangeCategories = []
        }) {
            CategoryMultiSelectionSheet(
                selectedCategories: $selectedCategoryChangeCategories,
                isSaving: vm.isChangingStudentCategory,
                onCancel: {
                    showCategoryChangeDialog = false
                },
                onSave: {
                    Task { await confirmCategoryChange(selectedCategoryChangeCategories) }
                }
            )
        }
        // Sheet Convites — ao fechar, recarrega alunos e convites
        .sheet(isPresented: $showInviteSheet, onDismiss: {
            Task {
                await loadInvitesIfPossible()
            }
        }) {
            inviteSheet
        }
    }

    private var isAnySheetPresented: Bool {
        showInviteSheet || showCategoryDialog || showCategoryChangeDialog
    }

    private var mainContent: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        studentsSectionSelector

                        switch selectedStudentsSection {
                        case .linked:
                            filterRow
                            contentCard
                        case .sentInvites:
                            pendingInvitesCard
                        case .receivedInvites:
                            pendingLinkRequestsCard
                        }
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity)
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: selectedCategory,
                        isHomeSelected: false,
                        isAlunosSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Theme.Colors.ink(0.35))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconSectionTitle(_ title: LocalizedStringKey, systemImage: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.ink(0.35))

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.ink(0.35))
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Abas (mesmo padrão visual de `nextFitTabSelector` da StudentNextFitWodView)

    private var studentsSectionSelector: some View {
        HStack(spacing: 0) {
            studentsSectionSegmentButton(title: "admin.trainer.linked_students", section: .linked)
            studentsSectionSegmentButton(title: "teacher_students.invites_sent_card_title", section: .sentInvites)
            studentsSectionSegmentButton(title: "teacher_students.invites_received_card_title", section: .receivedInvites)
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
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
    }

    // Segmento: selecionado com preenchimento (verde militar no Tema Claro / verde original no Tema Escuro);
    // não selecionado transparente, sem borda.
    private func studentsSectionSegmentButton(title: LocalizedStringKey, section: StudentsSection) -> some View {
        let isSelected = selectedStudentsSection == section
        let isLightSelected = appTheme == .light && isSelected

        return Button {
            selectedStudentsSection = section
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

    private var filterRow: some View {
        HStack(spacing: 6) {
            filterChip(title: "common.all", isSelected: filter == nil) { filter = nil }
            filterChip(title: "video.category.crossfit", isSelected: filter == .crossfit) { filter = .crossfit }
            filterChip(title: "video.category.gym", isSelected: filter == .academia) { filter = .academia }
            filterChip(title: "video.category.home", isSelected: filter == .emCasa) { filter = .emCasa }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(
        title: LocalizedStringKey,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                // Tema Claro: selecionado em verde militar (#29452C) com texto branco; demais em verde claro com texto escuro.
                // Tema Escuro: valores originais.
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: isSelected ? Color.white : LightColors.primaryText))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 6)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(
                    AppThemeColor(
                        dark: isSelected ? Theme.Colors.primaryGreen.opacity(0.18) : Color.black.opacity(0.68),
                        // Tema Claro (selecionado): mesmo verde militar/transparência do botão Sair da ProfileView.
                        light: isSelected ? AppThemePalette.lightBar.opacity(0.80) : LightColors.innerSurface
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            AppThemeColor(
                                dark: isSelected ? Theme.Colors.primaryGreen.opacity(0.30) : Theme.Colors.primaryGreen.opacity(0.28),
                                light: LightColors.chevron
                            ),
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                // Profundidade somente no Tema Claro (referência: AdminProfileSelectionView); Tema Escuro sem sombra
                .shadow(
                    color: appTheme == .light ? .black.opacity(isSelected ? 0.25 : 0.10) : .clear,
                    radius: appTheme == .light ? (isSelected ? 10 : 4) : 0,
                    y: appTheme == .light ? (isSelected ? 6 : 2) : 0
                )
        }
        .buttonStyle(.plain)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            iconSectionTitle("ui.linked_students", systemImage: "person.2.fill")
                .padding(.top, 14)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                if vm.isLoading {
                    loadingView
                } else if let msg = vm.errorMessage {
                    errorView(message: msg)
                } else {
                    let list = vm.filteredStudents(filter: filter)
                    if list.isEmpty { emptyView } else { studentsList(list) }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func studentsList(_ list: [AppUser]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.offset) { idx, student in

                HStack(spacing: 14) {

                    UserAvatarView(base64: student.photoBase64, size: 28)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(student.name)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                        Text(
                            String(
                                format: AppLocalization.string("ui.category_value", locale: locale),
                                locale: locale,
                                arguments: [combinedCategoryText(student)]
                            )
                        )
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.ink(0.55))
                    }

                    Spacer()

                    Menu {
                        Button {
                            studentPendingCategoryChange = student
                            selectedCategoryChangeCategories = Set(
                                vm.linkedCategories(for: student.id ?? "")
                            )
                            showCategoryChangeDialog = true
                        } label: {
                            Label(LocalizedStringKey("ui.change_category"), systemImage: "arrow.triangle.2.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.55).dark, light: LightColors.iconInk))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isChangingStudentCategory)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.chevron))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard let sid = student.id, !sid.isEmpty else {
                        vm.errorMessage = AppLocalization.string(
                            "ui.invalid_student_id_not_found",
                            locale: locale
                        )
                        return
                    }

                    let resolvedCategory = resolveCategoryForNavigation(student: student)
                    path.append(.teacherStudentDetail(student, resolvedCategory))
                }

                if idx < list.count - 1 {
                    Divider()
                        .background(Theme.Colors.divider)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("ui.loading_students")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("workout.oops_unable_to_load")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .multilineTextAlignment(.center)

            Button {
                Task { await loadAllStudents() }
            } label: {
                Text("ui.try_again")
                    .padding(.horizontal, 14)
                    .primaryGreenActionButton()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppThemeColor(dark: Color.clear, light: LightColors.chevron), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Text("ui.no_student_found")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

            Text("ui.link_students_to_your_profile_for_them_to_appear_here")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.ink(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func loadAllStudents() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.errorMessage = AppLocalization.string(
                "ui.unable_to_identify_the_signed_in_trainer",
                locale: locale
            )
            return
        }
        await vm.loadStudents(teacherId: teacherId, force: true)
    }

    private func loadInitialData() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.clearActiveTeacherData()
            vm.errorMessage = AppLocalization.string(
                "ui.unable_to_identify_the_signed_in_trainer",
                locale: locale
            )
            return
        }

        UserDefaults.standard.set(Date(), forKey: studentActivitiesLastSeenKey(teacherId: teacherId))

        async let students: Void = vm.loadStudents(teacherId: teacherId)
        async let invites: Void = vm.loadInvites(teacherId: teacherId)
        async let requests: Void = vm.loadPendingLinkRequests(teacherId: teacherId)
        _ = await (students, invites, requests)
        vm.removeLinkedStudentsFromPendingLinkRequests(teacherId: teacherId)
    }

    private func confirmCategoryChange(_ categories: Set<TreinoTipo>) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setLinkError(AppLocalization.string(
                "ui.unable_to_identify_the_signed_in_trainer",
                locale: locale
            ))
            return
        }
        guard let student = studentPendingCategoryChange,
              let studentId = student.id,
              !studentId.isEmpty
        else {
            vm.setLinkError(AppLocalization.string(
                "ui.unable_to_identify_the_student_to_change_the_category",
                locale: locale
            ))
            return
        }

        let didSave = await vm.setStudentCategories(
            teacherId: teacherId,
            studentId: studentId,
            categories: Array(categories),
            locale: locale
        )
        if didSave {
            showCategoryChangeDialog = false
        }
    }

    private var pendingInvitesCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            iconSectionTitle("student_teachers.sent_invitations_section", systemImage: "paperplane.fill")
                .padding(.top, 14)
                .padding(.bottom, 10)

            let pending = vm.pendingInvites

            // Estado vazio (mesmo padrão visual da mensagem de "Convites recebidos")
            if pending.isEmpty && !vm.isInvitesLoading {
                Text("student_teachers.no_pending_invitation")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }

            ForEach(Array(pending.enumerated()), id: \.offset) { idx, inv in

                HStack(spacing: 12) {

                    Image(systemName: "clock.fill")
                        .foregroundColor(appTheme == .light ? LightColors.pendingStatus : .yellow.opacity(0.75))
                        .font(.system(size: 15))
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(inv.studentEmail)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text("ui.pending")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(appTheme == .light ? LightColors.pendingStatus : .yellow.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.yellow.opacity(0.12)))
                        }
                    }

                    Spacer()

                    Menu {
                        Button(role: .destructive) {
                            invitePendingCancel = inv
                            showCancelInviteConfirm = true
                        } label: {
                            Label(LocalizedStringKey("ui.cancel_invitation"), systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.55).dark, light: LightColors.iconInk))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isInvitesLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())

                if idx < pending.count - 1 {
                    Divider()
                        .background(Theme.Colors.divider)
                        .padding(.horizontal, 16)
                }
            }

            Color.clear.frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private var pendingLinkRequestsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            iconSectionTitle("student_teachers.received_invitations_section", systemImage: "envelope.open.fill")
                .padding(.top, 14)
                .padding(.bottom, 10)

            if vm.isLinkRequestsLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("ui.loading_requests")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if vm.pendingLinkRequests.isEmpty {
                Text("ui.no_pending_request")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            } else {
                ForEach(Array(vm.pendingLinkRequests.enumerated()), id: \.offset) { index, item in
                    linkRequestRow(item)

                    if index < vm.pendingLinkRequests.count - 1 {
                        Divider()
                            .background(Theme.Colors.divider)
                            .padding(.horizontal, 16)
                    }
                }

                Color.clear.frame(height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func linkRequestRow(_ item: StudentLinkItem) -> some View {
        HStack(spacing: 14) {
            UserAvatarView(base64: item.photoBase64, size: 28)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                if !item.studentEmail.isEmpty {
                    Text(item.studentEmail)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.ink(0.35))
                }
            }

            Spacer()

            Menu {
                Button {
                    studentPendingLink = item
                    selectedLinkCategories = []
                    showCategoryDialog = true
                } label: {
                    Label(LocalizedStringKey("ui.accept_link"), systemImage: "checkmark")
                }

                Button(role: .destructive) {
                    linkRequestPendingDecline = item
                    showDeclineLinkRequestConfirm = true
                } label: {
                    Label(LocalizedStringKey("ui.decline_invitation"), systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.55).dark, light: LightColors.iconInk))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(vm.isLinkRequestsLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func confirmCancelInvite() async {
        guard let inv = invitePendingCancel,
              let invId = inv.id, !invId.isEmpty,
              let teacherId = session.uid, !teacherId.isEmpty
        else {
            invitePendingCancel = nil
            return
        }

        await vm.cancelInvite(inviteId: invId, teacherId: teacherId)
        invitePendingCancel = nil
    }

    private func confirmDeclineLinkRequest() async {
        guard let teacherId = session.uid, !teacherId.isEmpty,
              let request = linkRequestPendingDecline
        else {
            linkRequestPendingDecline = nil
            return
        }

        await vm.declineLinkRequest(
            teacherId: teacherId,
            requestId: request.requestId,
            locale: locale
        )
        linkRequestPendingDecline = nil
    }

    private func confirmLink(_ categories: Set<TreinoTipo>) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setLinkError(AppLocalization.string(
                "ui.unable_to_identify_the_signed_in_trainer",
                locale: locale
            ))
            return
        }
        guard let item = studentPendingLink else { return }

        let didSave = await vm.approveRequestAndLinkStudent(
            teacherId: teacherId,
            requestId: item.requestId,
            studentId: item.studentId,
            categories: Array(categories),
            locale: locale
        )
        if didSave {
            showCategoryDialog = false
        }
    }

    private struct CategoryMultiSelectionSheet: View {
        @Binding var selectedCategories: Set<TreinoTipo>
        let isSaving: Bool
        let onCancel: () -> Void
        let onSave: () -> Void

        private let categories: [TreinoTipo] = [.crossfit, .academia, .emCasa]

        var body: some View {
            ZStack {
                Theme.Colors.sheetBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Theme.Colors.ink(0.18))
                        .frame(width: 44, height: 5)
                        .padding(.top, 10)

                    Text("ui.select_link_category")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink())
                        .padding(.top, 4)

                    // Itens individuais no mesmo padrão visual de `quickAccessEditorItem(_:)` da TeacherDashboardView
                    VStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            let isSelected = selectedCategories.contains(category)

                            Button {
                                toggle(category)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: iconName(for: category))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.iconInk))
                                        .frame(width: 22)

                                    Text(title(for: category))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppThemeColor(dark: isSelected ? .green : .white.opacity(0.35), light: LightColors.chevron))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(AppThemeColor(dark: Color.white.opacity(0.06), light: LightColors.innerSurface))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            AppThemeColor(
                                                dark: isSelected ? Theme.Colors.primaryGreen.opacity(0.35) : Color.white.opacity(0.08),
                                                light: LightColors.chevron
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isSaving)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    Spacer(minLength: 0)

                    HStack(spacing: 12) {
                        Button(action: onCancel) {
                            Text("common.cancel")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.Colors.ink(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.Colors.ink(0.10))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppThemeColor(dark: Color.clear, light: LightColors.chevron), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving)

                        Button(action: onSave) {
                            Text("common.save")
                                .frame(maxWidth: .infinity)
                                // Tema Claro (habilitado): cores do botão Sair da ProfileView. Demais casos: `primaryGreenActionButton()` original.
                                .modifier(TeacherStudentsLightBarActionButtonModifier())
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedCategories.isEmpty || isSaving)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
            }
            .presentationDetents([.fraction(0.50)])
        }

        private func toggle(_ category: TreinoTipo) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }

        private func title(for category: TreinoTipo) -> LocalizedStringKey {
            switch category {
            case .crossfit: "video.category.crossfit"
            case .academia: "video.category.gym"
            case .emCasa: "video.category.home"
            }
        }

        // Mesmos SF Symbols das categorias usados em TeacherWorkoutTemplatesComponents
        private func iconName(for category: TreinoTipo) -> String {
            switch category {
            case .crossfit: "figure.strengthtraining.traditional"
            case .academia: "dumbbell"
            case .emCasa: "house.fill"
            }
        }
    }

    private func studentActivitiesLastSeenKey(teacherId: String) -> String {
        "teacherStudentActivitiesLastSeen.\(teacherId)"
    }

    // MARK: - ✅ Categoria combinada (vínculo / cadastro) + navegação

    private func combinedCategoryText(_ student: AppUser) -> String {
        guard let studentId = student.id, !studentId.isEmpty else {
            return "—"
        }

        let categories = vm.linkedCategories(for: studentId)
        guard !categories.isEmpty else { return "—" }

        return categories
            .map(localizedCategoryTitle)
            .joined(separator: " / ")
    }

    private func localizedCategoryTitle(_ category: TreinoTipo) -> String {
        switch category {
        case .crossfit:
            AppLocalization.string("video.category.crossfit", locale: locale)
        case .academia:
            AppLocalization.string("video.category.gym", locale: locale)
        case .emCasa:
            AppLocalization.string("video.category.home", locale: locale)
        }
    }

    private func categoryFromStudentProfile(_ student: AppUser) -> TreinoTipo? {
        if let cat = mapCategoryStringToTreinoTipo(student.focusArea) {
            return cat
        }

        let defaultRaw: String? = {
            let mirror = Mirror(reflecting: student)
            for child in mirror.children {
                if child.label == "defaultCategory", let v = child.value as? String {
                    return v
                }
            }
            return nil
        }()

        if let cat = mapCategoryStringToTreinoTipo(defaultRaw) {
            return cat
        }

        return nil
    }

    private func resolveCategoryForNavigation(student: AppUser) -> TreinoTipo {
        if let filter {
            return filter
        }
        if let studentId = student.id,
           let linkedCategory = vm.linkedCategory(
               for: studentId,
               preferred: categoryFromStudentProfile(student) ?? selectedCategory
           ) {
            return linkedCategory
        }
        return categoryFromStudentProfile(student) ?? selectedCategory
    }

    private func mapCategoryStringToTreinoTipo(_ rawOpt: String?) -> TreinoTipo? {
        let raw = (rawOpt ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !raw.isEmpty else { return nil }

        if raw == FocusAreaDTO.CROSSFIT.rawValue.lowercased() { return .crossfit }
        if raw == FocusAreaDTO.GYM.rawValue.lowercased() { return .academia }
        if raw == FocusAreaDTO.HOME.rawValue.lowercased() { return .emCasa }

        if raw.contains("cross") { return .crossfit }
        if raw.contains("gym") || raw.contains("academ") { return .academia }
        if raw.contains("casa") || raw.contains("home") { return .emCasa }

        if raw == TreinoTipo.crossfit.rawValue.lowercased() { return .crossfit }
        if raw == TreinoTipo.academia.rawValue.lowercased() { return .academia }
        if raw == TreinoTipo.emCasa.rawValue.lowercased() { return .emCasa }

        return nil
    }

    // MARK: - ✅ Invite Sheet

    private var inviteSheet: some View {
        ZStack {
            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ✅ AJUSTE 2: ScrollView para evitar “expansão” que corta conteúdo ao focar no e-mail e ao trocar abas
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        Capsule()
                            .fill(Theme.Colors.ink(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("ui.invite_student")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink())
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            inviteByEmailCard
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Tema Claro: mesmo verde-claro (innerSurface) dos cards de seleção de categoria. Tema Escuro: valores originais.
                        .background(AppThemeColor(dark: Theme.Colors.cardBackground.dark, light: LightColors.innerSurface))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppThemeColor(dark: Theme.Colors.ink(0.08).dark, light: LightColors.chevron), lineWidth: 1)
                        )
                        .shadow(
                            color: appTheme == .light ? .black.opacity(0.25) : .clear,
                            radius: appTheme == .light ? 10 : 0,
                            y: appTheme == .light ? 6 : 0
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                HStack(spacing: 12) {
                    Button {
                        showInviteSheet = false
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
                                    .stroke(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: LightColors.chevron), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isInvitesLoading)

                    Button {
                        Task {
                            guard let teacherId = session.uid, !teacherId.isEmpty else {
                                vm.setInviteError(AppLocalization.string(
                                    "ui.unable_to_identify_the_signed_in_trainer",
                                    locale: locale
                                ))
                                return
                            }
                            await vm.sendInviteByEmail(
                                teacherId: teacherId,
                                studentEmail: inviteEmail,
                                category: selectedCategory,
                                locale: locale
                            )
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Spacer()
                            if vm.isInvitesLoading {
                                ProgressView()
                            } else {
                                // Tema Claro: ícone herda o branco do botão; Tema Escuro: comportamento original.
                                if appTheme == .light {
                                    Image(systemName: "paperplane.fill")
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .appThemeIconForeground()
                                }
                                Text("ui.send_invitation")
                            }
                            Spacer()
                        }
                        // Tema Claro (habilitado): cores do botão Sair da ProfileView. Demais casos: `primaryGreenActionButton()` original.
                        .modifier(TeacherStudentsLightBarActionButtonModifier())
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isInvitesLoading || inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(1.0 / 4.0)])
        // ✅ impede a sheet de “crescer” agressivamente por mudança de conteúdo; rola por dentro quando necessário
        .presentationContentInteraction(.scrolls)
        .alert("common.error", isPresented: $vm.showInviteErrorAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(vm.inviteErrorMessage ?? AppLocalization.string("common.unexpected_error", locale: locale))
        }
        .alert("ui.success", isPresented: $vm.showInviteSuccessAlert) {
            // ✅ OK fecha o modal e limpa o campo — o onDismiss da sheet recarrega dados
            Button("common.ok") {
                inviteEmail = ""
                showInviteSheet = false
            }
        } message: {
            Text(vm.inviteSuccessMessage ?? AppLocalization.string("ui.invitation_sent", locale: locale))
        }
    }

    private var inviteByEmailCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.icon(Theme.Colors.ink(0.35)).dark, light: LightColors.iconInk))

                TextField("ui.student_email", text: $inviteEmail)
                    .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.92).dark, light: LightColors.primaryText))
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .font(.system(size: 16, weight: .semibold))

                if !inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { inviteEmail = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppThemeColor(dark: Theme.Colors.icon(Theme.Colors.ink(0.35)).dark, light: LightColors.iconInk))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            // Tema Claro: mesmo padrão dos campos do modal Adicionar Vídeo. Tema Escuro: valores originais.
            .background(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: Theme.Colors.ink(0.10).light))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: LightColors.chevron), lineWidth: 1)
            )
        }
    }

    private func loadInvitesIfPossible(force: Bool = false) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else { return }
        await vm.loadInvites(teacherId: teacherId, force: force)
    }
}

// Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView
private let teacherStudentsDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

// Tema Claro + habilitado: mesmas cores/transparências do botão Sair da ProfileView,
// preservando fonte, padding e arredondamento de `primaryGreenActionButton()`.
// Tema Escuro ou desabilitado: aplica exatamente o `primaryGreenActionButton()` original.
private struct TeacherStudentsLightBarActionButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        if appTheme == .light && isEnabled {
            content
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(teacherStudentsDarkGreenBorder, lineWidth: 1)
                )
        } else {
            content
                .primaryGreenActionButton()
        }
    }
}
