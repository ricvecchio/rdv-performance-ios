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
    @StateObject private var vm: TeacherStudentsListViewModel

    @State private var filter: TreinoTipo? = nil
    private let contentMaxWidth: CGFloat = 380

    @State private var studentPendingCategoryChange: AppUser? = nil
    @State private var showCategoryChangeDialog: Bool = false
    @State private var selectedCategoryChangeCategories: Set<TreinoTipo> = []

    // Modal convite
    @State private var showInviteSheet: Bool = false
    @State private var inviteTab: InviteTab = .invite
    @State private var inviteEmail: String = ""

    // ✅ Cancelamento de convite pendente na lista principal
    @State private var invitePendingCancel: TeacherStudentInviteFS? = nil
    @State private var showCancelInviteConfirm: Bool = false

    @State private var studentPendingLink: StudentLinkItem? = nil
    @State private var showCategoryDialog: Bool = false
    @State private var selectedLinkCategories: Set<TreinoTipo> = []

    @State private var linkRequestPendingDecline: StudentLinkItem? = nil
    @State private var showDeclineLinkRequestConfirm: Bool = false

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
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("common.students")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            // ✅ NOVO: botão Convidar + avatar
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {

                    Button {
                        inviteTab = .invite
                        inviteEmail = ""
                        showInviteSheet = true
                        Task { await loadInvitesIfPossible() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                            Text("ui.invite")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
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

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header
                        filterRow
                        contentCard
                        if vm.hasLoadedStudents && !vm.pendingInvites.isEmpty {
                            pendingInvitesCard
                        }
                        pendingLinkRequestsCard
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ui.select_a_student_to_view_details_and_create_workouts")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 6)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Theme.Colors.primaryGreen.opacity(0.18) : Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Theme.Colors.primaryGreen.opacity(0.30) : Color.white.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            sectionTitle("ui.linked_students")
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
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func studentsList(_ list: [AppUser]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.offset) { idx, student in

                HStack(spacing: 14) {

                    StudentAvatarView(base64: student.photoBase64, size: 28)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(student.name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))

                        Text(
                            String(
                                format: AppLocalization.string("ui.category_value", locale: locale),
                                locale: locale,
                                arguments: [combinedCategoryText(student)]
                            )
                        )
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
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
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isChangingStudentCategory)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.35))
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
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("workout.oops_unable_to_load")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button {
                Task { await loadAllStudents() }
            } label: {
                Text("ui.try_again")
                    .padding(.horizontal, 14)
                    .primaryGreenActionButton()
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
                .foregroundColor(.white.opacity(0.92))

            Text("ui.link_students_to_your_profile_for_them_to_appear_here")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
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

            sectionTitle("student_teachers.sent_invitations_section")
                .padding(.top, 14)
                .padding(.bottom, 10)

            let pending = vm.pendingInvites
            ForEach(Array(pending.enumerated()), id: \.offset) { idx, inv in

                HStack(spacing: 12) {

                    Image(systemName: "clock.fill")
                        .foregroundColor(.yellow.opacity(0.75))
                        .font(.system(size: 15))
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(inv.studentEmail)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text("ui.pending")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.yellow.opacity(0.85))
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
                            .foregroundColor(.white.opacity(0.55))
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
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private var pendingLinkRequestsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("student_teachers.received_invitations_section")
                .padding(.top, 14)
                .padding(.bottom, 10)

            if vm.isLinkRequestsLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("ui.loading_requests")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if vm.pendingLinkRequests.isEmpty {
                Text("ui.no_pending_request")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
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
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func linkRequestRow(_ item: StudentLinkItem) -> some View {
        HStack(spacing: 14) {
            StudentAvatarView(base64: item.photoBase64, size: 28)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))

                if !item.studentEmail.isEmpty {
                    Text(item.studentEmail)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
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
                    .foregroundColor(.white.opacity(0.55))
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
                Theme.Colors.headerBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 44, height: 5)
                        .padding(.top, 10)

                    Text("ui.select_link_category")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    VStack(spacing: 0) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                toggle(category)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(
                                            selectedCategories.contains(category)
                                                ? Theme.Colors.primaryGreen
                                                : .white.opacity(0.35)
                                        )
                                        .font(.system(size: 20, weight: .semibold))

                                    Text(title(for: category))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.92))

                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isSaving)

                            if category != categories.last {
                                Divider()
                                    .background(Theme.Colors.divider)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                    Spacer(minLength: 0)

                    HStack(spacing: 12) {
                        Button(action: onCancel) {
                            Text("common.cancel")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.10))
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving)

                        Button(action: onSave) {
                            Text("common.save")
                                .frame(maxWidth: .infinity)
                                .primaryGreenActionButton()
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

    private enum InviteTab: Int, CaseIterable {
        case invite = 0
        case sent = 1

        func title(locale: Locale) -> String {
            switch self {
            case .invite:
                AppLocalization.string("ui.invite", locale: locale)
            case .sent:
                AppLocalization.string("student_teachers.sent_invitations_section", locale: locale)
            }
        }
    }

    private var inviteSheet: some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // ✅ AJUSTE 2: ScrollView para evitar “expansão” que corta conteúdo ao focar no e-mail e ao trocar abas
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("ui.invite_student")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Picker("", selection: $inviteTab) {
                                ForEach(InviteTab.allCases, id: \.rawValue) { tab in
                                    Text(tab.title(locale: locale)).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)

                            Group {
                                switch inviteTab {
                                case .invite:
                                    inviteByEmailCard
                                case .sent:
                                    invitesSentCard
                                }
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
                .scrollDismissesKeyboard(.interactively)

                if inviteTab == .invite {
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
                                Image(systemName: "paperplane.fill")
                                Text("ui.send_invitation")
                            }
                            Spacer()
                        }
                        .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isInvitesLoading || inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                }
            }
        }
        .presentationDetents([.fraction(2.0 / 3.0)])
        // ✅ impede a sheet de “crescer” agressivamente por mudança de conteúdo; rola por dentro quando necessário
        .presentationContentInteraction(.scrolls)
        .onAppear {
            Task { await loadInvitesIfPossible() }
        }
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

            Text("ui.invite_by_email")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.white.opacity(0.35))

                TextField("ui.student_email", text: $inviteEmail)
                    .foregroundColor(.white.opacity(0.92))
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .font(.system(size: 16, weight: .semibold))

                if !inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { inviteEmail = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.10))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )

            Text("ui.the_student_will_only_appear_in_your_list_after_accepting_the_app_invitation")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    private var invitesSentCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("student_teachers.sent_invitations_section")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Spacer()

                Button {
                    Task { await loadInvitesIfPossible(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .disabled(vm.isInvitesLoading)
            }

            if vm.isInvitesLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("ui.loading_invitations")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.vertical, 6)
            } else if let msg = vm.invitesErrorMessageInline {
                Text(msg)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.leading)
            } else if vm.invites.isEmpty {
                Text("ui.no_invitation_has_been_sent_yet")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.invites.enumerated()), id: \.offset) { idx, inv in
                        inviteRow(inv)
                        if idx < vm.invites.count - 1 {
                            Divider()
                                .background(Theme.Colors.divider)
                                .padding(.leading, 12)
                        }
                    }
                }
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
            }
        }
    }

    private func inviteRow(_ inv: TeacherStudentInviteFS) -> some View {
        let statusText = vm.statusText(inv.status, locale: locale)

        return HStack(spacing: 12) {
            Image(systemName: "envelope")
                .foregroundColor(.white.opacity(0.55))

            VStack(alignment: .leading, spacing: 4) {
                Text(inv.studentEmail)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            if inv.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "pending",
               let id = inv.id, !id.isEmpty {
                Button {
                    Task {
                        guard let teacherId = session.uid, !teacherId.isEmpty else { return }
                        await vm.cancelInvite(inviteId: id, teacherId: teacherId)
                    }
                } label: {
                    Text("common.cancel")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.red.opacity(0.16)))
                }
                .buttonStyle(.plain)
                .disabled(vm.isInvitesLoading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private func loadInvitesIfPossible(force: Bool = false) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else { return }
        await vm.loadInvites(teacherId: teacherId, force: force)
    }
}
