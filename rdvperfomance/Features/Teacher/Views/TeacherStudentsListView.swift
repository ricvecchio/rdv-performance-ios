// TeacherStudentsListView.swift — Lista de alunos do professor com filtros e ações de desvincular
import SwiftUI
import Combine

struct TeacherStudentsListView: View {

    @Binding var path: [AppRoute]
    let selectedCategory: TreinoTipo
    let initialFilter: TreinoTipo?
    let onBack: () -> Void

    @EnvironmentObject private var session: AppSession
    @StateObject private var vm: TeacherStudentsListViewModel

    @State private var filter: TreinoTipo? = nil
    private let contentMaxWidth: CGFloat = 380

    @State private var studentPendingCategoryChange: AppUser? = nil
    @State private var showCategoryChangeDialog: Bool = false

    // Modal convite
    @State private var showInviteSheet: Bool = false
    @State private var inviteTab: InviteTab = .invite
    @State private var inviteEmail: String = ""

    // ✅ Cancelamento de convite pendente na lista principal
    @State private var invitePendingCancel: TeacherStudentInviteFS? = nil
    @State private var showCancelInviteConfirm: Bool = false

    @State private var studentPendingLink: StudentLinkItem? = nil
    @State private var showCategoryDialog: Bool = false

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
        // ✅ AJUSTE 1: desfoca a tela de fundo quando o modal "Convidar aluno" estiver aberto
        .blur(radius: showInviteSheet ? 8 : 0)
        .animation(.easeInOut(duration: 0.18), value: showInviteSheet)

        .onAppear {
            filter = initialFilter
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
                Text("Alunos")
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
                            Text("Convidar")
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
        .alert("Cancelar convite?", isPresented: $showCancelInviteConfirm) {
            Button("Cancelar", role: .cancel) { invitePendingCancel = nil }
            Button("Confirmar cancelamento", role: .destructive) {
                Task { await confirmCancelInvite() }
            }
        } message: {
            if let inv = invitePendingCancel {
                Text("O convite enviado para \(inv.studentEmail) será cancelado.")
            } else {
                Text("O convite será cancelado.")
            }
        }
        .alert("Recusar convite?", isPresented: $showDeclineLinkRequestConfirm) {
            Button("Cancelar", role: .cancel) { linkRequestPendingDecline = nil }
            Button("Recusar", role: .destructive) {
                Task { await confirmDeclineLinkRequest() }
            }
        } message: {
            Text("Deseja recusar esta solicitação de vínculo?")
        }
        .alert("Erro", isPresented: $vm.showLinkErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.linkErrorMessage ?? "Ocorreu um erro.")
        }
        .alert("Sucesso", isPresented: $vm.showLinkSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.linkSuccessMessage ?? "Aluno vinculado.")
        }
        .confirmationDialog(
            "Selecione a categoria do vínculo",
            isPresented: $showCategoryDialog,
            titleVisibility: .visible
        ) {
            Button(TreinoTipo.crossfit.displayName) { Task { await confirmLink(.crossfit) } }
            Button(TreinoTipo.academia.displayName) { Task { await confirmLink(.academia) } }
            Button(TreinoTipo.emCasa.displayName) { Task { await confirmLink(.emCasa) } }
            Button("Cancelar", role: .cancel) { studentPendingLink = nil }
        } message: {
            Text(linkDialogMessageText())
        }
        .confirmationDialog(
            "Selecione a categoria do vínculo",
            isPresented: $showCategoryChangeDialog,
            titleVisibility: .visible
        ) {
            Button(TreinoTipo.crossfit.displayName) { Task { await confirmCategoryChange(.crossfit) } }
            Button(TreinoTipo.academia.displayName) { Task { await confirmCategoryChange(.academia) } }
            Button(TreinoTipo.emCasa.displayName) { Task { await confirmCategoryChange(.emCasa) } }
            Button("Todos") { Task { await confirmAllCategoryChanges() } }
            Button("Cancelar", role: .cancel) { studentPendingCategoryChange = nil }
        } message: {
            Text(categoryChangeDialogMessageText())
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
            Text("Selecione um aluno para ver detalhes e criar treinos.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterRow: some View {
        HStack(spacing: 6) {
            filterChip(title: "Todos", isSelected: filter == nil) { filter = nil }
            filterChip(title: TreinoTipo.crossfit.displayName, isSelected: filter == .crossfit) { filter = .crossfit }
            filterChip(title: TreinoTipo.academia.displayName, isSelected: filter == .academia) { filter = .academia }
            filterChip(title: "Em Casa", isSelected: filter == .emCasa) { filter = .emCasa }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
            sectionTitle("ALUNOS VINCULADOS")
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

                        Text("Categoria: \(combinedCategoryText(student))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    Menu {
                        Button {
                            studentPendingCategoryChange = student
                            showCategoryChangeDialog = true
                        } label: {
                            Label("Alterar categoria", systemImage: "arrow.triangle.2.circlepath")
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
                        vm.errorMessage = "Aluno inválido: id não encontrado."
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
            Text("Carregando alunos...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Text("Ops! Não foi possível carregar.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button {
                Task { await loadAllStudents() }
            } label: {
                Text("Tentar novamente")
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
            Text("Nenhum aluno encontrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Vincule alunos ao seu perfil para aparecerem aqui.")
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
            vm.errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        await vm.loadStudents(teacherId: teacherId, force: true)
    }

    private func loadInitialData() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.clearActiveTeacherData()
            vm.errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        await vm.loadStudents(teacherId: teacherId)
        UserDefaults.standard.set(Date(), forKey: studentActivitiesLastSeenKey(teacherId: teacherId))

        async let invites: Void = vm.loadInvites(teacherId: teacherId)
        async let requests: Void = vm.loadPendingLinkRequests(teacherId: teacherId)
        _ = await (invites, requests)
        vm.removeLinkedStudentsFromPendingLinkRequests(teacherId: teacherId)
    }

    private func categoryChangeDialogMessageText() -> String {
        guard let student = studentPendingCategoryChange else {
            return "Selecione uma categoria."
        }
        return "Aluno: \(student.name)"
    }

    private func confirmCategoryChange(_ newCategory: TreinoTipo) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setLinkError("Não foi possível identificar o professor logado.")
            studentPendingCategoryChange = nil
            return
        }
        guard let student = studentPendingCategoryChange,
              let studentId = student.id,
              !studentId.isEmpty,
              let currentCategory = vm.linkedCategory(
                  for: studentId,
                  preferred: filter ?? categoryFromStudentProfile(student) ?? selectedCategory
              )
        else {
            vm.setLinkError("Não foi possível identificar a categoria atual do vínculo.")
            studentPendingCategoryChange = nil
            return
        }

        await vm.changeStudentCategory(
            teacherId: teacherId,
            studentId: studentId,
            currentCategory: currentCategory,
            newCategory: newCategory
        )
        studentPendingCategoryChange = nil
    }

    private func confirmAllCategoryChanges() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setLinkError("Não foi possível identificar o professor logado.")
            studentPendingCategoryChange = nil
            return
        }
        guard let student = studentPendingCategoryChange,
              let studentId = student.id,
              !studentId.isEmpty
        else {
            vm.setLinkError("Não foi possível identificar o aluno para alterar a categoria.")
            studentPendingCategoryChange = nil
            return
        }

        await vm.ensureStudentCategories(
            teacherId: teacherId,
            studentId: studentId,
            categories: [.crossfit, .academia, .emCasa]
        )
        studentPendingCategoryChange = nil
    }

    private var pendingInvitesCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            sectionTitle("CONVITES ENVIADOS")
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
                            Text("Pendente")
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
                            Label("Cancelar convite", systemImage: "xmark.circle")
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
            sectionTitle("CONVITES RECEBIDOS")
                .padding(.top, 14)
                .padding(.bottom, 10)

            if vm.isLinkRequestsLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Carregando solicitações...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if vm.pendingLinkRequests.isEmpty {
                Text("Nenhuma solicitação pendente")
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
                    showCategoryDialog = true
                } label: {
                    Label("Aceitar vínculo", systemImage: "checkmark")
                }

                Button(role: .destructive) {
                    linkRequestPendingDecline = item
                    showDeclineLinkRequestConfirm = true
                } label: {
                    Label("Recusar convite", systemImage: "xmark.circle")
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

        await vm.declineLinkRequest(teacherId: teacherId, requestId: request.requestId)
        linkRequestPendingDecline = nil
    }

    private func linkDialogMessageText() -> String {
        guard let item = studentPendingLink else { return "Selecione uma categoria." }
        return "Aluno: \(item.name)\nEscolha a categoria para vincular."
    }

    private func confirmLink(_ category: TreinoTipo) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setLinkError("Não foi possível identificar o professor logado.")
            studentPendingLink = nil
            return
        }
        guard let item = studentPendingLink else { return }

        await vm.approveRequestAndLinkStudent(
            teacherId: teacherId,
            requestId: item.requestId,
            studentId: item.studentId,
            category: category.firestoreKey
        )
        studentPendingLink = nil
    }

    private func studentActivitiesLastSeenKey(teacherId: String) -> String {
        "teacherStudentActivitiesLastSeen.\(teacherId)"
    }

    // MARK: - ✅ Categoria combinada (vínculo / cadastro) + navegação

    private func combinedCategoryText(_ student: AppUser) -> String {
        let profile = categoryFromStudentProfile(student)
        let link = filter ?? student.id.flatMap {
            vm.linkedCategory(for: $0, preferred: profile ?? selectedCategory)
        }
        guard let link else { return profile?.displayName ?? "—" }
        guard let profile else {
            return link.displayName
        }
        if link == profile {
            return link.displayName
        }
        return "\(link.displayName) / \(profile.displayName)"
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

        var title: String {
            switch self {
            case .invite: return "Convidar"
            case .sent: return "Convites"
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

                        Text("Convidar aluno")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 14) {
                            Picker("", selection: $inviteTab) {
                                ForEach(InviteTab.allCases, id: \.rawValue) { tab in
                                    Text(tab.title).tag(tab)
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
                                vm.setInviteError("Não foi possível identificar o professor logado.")
                                return
                            }
                            await vm.sendInviteByEmail(teacherId: teacherId, studentEmail: inviteEmail, category: selectedCategory)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Spacer()
                            if vm.isInvitesLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Enviar convite")
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
        .alert("Erro", isPresented: $vm.showInviteErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.inviteErrorMessage ?? "Ocorreu um erro.")
        }
        .alert("Sucesso", isPresented: $vm.showInviteSuccessAlert) {
            // ✅ OK fecha o modal e limpa o campo — o onDismiss da sheet recarrega dados
            Button("OK") {
                inviteEmail = ""
                showInviteSheet = false
            }
        } message: {
            Text(vm.inviteSuccessMessage ?? "Convite enviado.")
        }
    }

    private var inviteByEmailCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("CONVIDAR POR E-MAIL")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.white.opacity(0.35))

                TextField("E-mail do aluno", text: $inviteEmail)
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

            Text("O aluno só aparecerá na sua lista após aceitar o convite no app.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    private var invitesSentCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("CONVITES ENVIADOS")
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
                    Text("Carregando convites...")
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
                Text("Nenhum convite enviado ainda.")
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
        let statusText = vm.statusText(inv.status)

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
                    Text("Cancelar")
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
