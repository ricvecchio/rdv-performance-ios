// TeacherStudentsListView.swift — Lista de alunos do professor com filtros e ações de desvincular
import SwiftUI
import Combine

struct TeacherStudentsListView: View {

    @Binding var path: [AppRoute]
    let selectedCategory: TreinoTipo
    let initialFilter: TreinoTipo?

    @EnvironmentObject private var session: AppSession
    @StateObject private var vm: TeacherStudentsListViewModel

    @State private var filter: TreinoTipo? = nil
    private let contentMaxWidth: CGFloat = 380

    @State private var studentPendingUnlink: AppUser? = nil
    @State private var showUnlinkConfirm: Bool = false

    // ✅ NOVO: modal convite
    @State private var showInviteSheet: Bool = false
    @State private var inviteTab: InviteTab = .invite
    @State private var inviteEmail: String = ""

    init(
        path: Binding<[AppRoute]>,
        selectedCategory: TreinoTipo,
        initialFilter: TreinoTipo?,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.selectedCategory = selectedCategory
        self.initialFilter = initialFilter
        _vm = StateObject(wrappedValue: TeacherStudentsListViewModel(repository: repository))
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header
                        filterRow
                        contentCard
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
        // ✅ AJUSTE 1: desfoca a tela de fundo quando o modal "Convidar aluno" estiver aberto
        .blur(radius: showInviteSheet ? 8 : 0)
        .animation(.easeInOut(duration: 0.18), value: showInviteSheet)

        .onAppear {
            filter = initialFilter
        }
        // ✅ FIX: garante reload quando session.uid ficar disponível (evita lista vazia por task rodar cedo demais)
        .task(id: session.uid ?? "") {
            await loadAllStudents()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
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
            ToolbarItem(placement: .navigationBarTrailing) {
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
        .alert("Desvincular aluno?", isPresented: $showUnlinkConfirm) {
            Button("Cancelar", role: .cancel) { studentPendingUnlink = nil }
            Button("Desvincular", role: .destructive) { Task { await confirmUnlink() } }
        } message: {
            Text(unlinkMessageText())
        }
        // ✅ NOVO: Sheet Convites
        .sheet(isPresented: $showInviteSheet) {
            inviteSheet
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Selecione um aluno para ver detalhes e criar treinos.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))

            Button {
                path.append(.teacherLinkStudent(category: selectedCategory))
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Vincular aluno")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FILTRO")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .padding(.horizontal, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {

                    filterChip(title: "Todos", isSelected: filter == nil) { filter = nil }

                    filterChip(title: TreinoTipo.crossfit.displayName, isSelected: filter == .crossfit) { filter = .crossfit }
                    filterChip(title: TreinoTipo.academia.displayName, isSelected: filter == .academia) { filter = .academia }
                    filterChip(title: TreinoTipo.emCasa.displayName, isSelected: filter == .emCasa) { filter = .emCasa }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green.opacity(0.16) : Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(isSelected ? Color.green.opacity(0.35) : Color.white.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 999))
        }
        .buttonStyle(.plain)
    }

    private var contentCard: some View {
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
                        Button(role: .destructive) {
                            studentPendingUnlink = student
                            showUnlinkConfirm = true
                        } label: {
                            Label("Desvincular", systemImage: "link.badge.minus")
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
                    .disabled(vm.isUnlinking)

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
                    innerDivider(leading: 54)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
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
        await vm.loadStudents(teacherId: teacherId)
    }

    private func unlinkMessageText() -> String {
        guard let student = studentPendingUnlink else {
            return "Tem certeza que deseja desvincular este aluno?"
        }

        if let chipCategory = filter {
            return "O aluno \"\(student.name)\" será desvinculado da categoria \(chipCategory.displayName)."
        } else {
            return "O aluno \"\(student.name)\" será desvinculado de todas as categorias."
        }
    }

    private func confirmUnlink() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.errorMessage = "Não foi possível identificar o professor logado."
            studentPendingUnlink = nil
            return
        }
        guard let student = studentPendingUnlink, let studentId = student.id, !studentId.isEmpty else {
            vm.errorMessage = "Não foi possível identificar o aluno para desvincular."
            studentPendingUnlink = nil
            return
        }

        await vm.unlinkStudent(
            teacherId: teacherId,
            studentId: studentId,
            categoryToRemove: filter
        )

        studentPendingUnlink = nil
        await loadAllStudents()
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - ✅ Categoria combinada (vínculo / cadastro) + navegação

    private func combinedCategoryText(_ student: AppUser) -> String {
        let profile = categoryFromStudentProfile(student)
        guard let link = filter else {
            return profile?.displayName ?? "—"
        }
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
        if let fromProfile = categoryFromStudentProfile(student) {
            return fromProfile
        }
        return selectedCategory
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
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // ✅ AJUSTE 2: ScrollView para evitar “expansão” que corta conteúdo ao focar no e-mail e ao trocar abas
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 48, height: 6)
                        .padding(.top, 10)

                    Text("Convidar aluno")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.top, 2)

                    Picker("", selection: $inviteTab) {
                        ForEach(InviteTab.allCases, id: \.rawValue) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    Group {
                        switch inviteTab {
                        case .invite:
                            inviteByEmailCard
                        case .sent:
                            invitesSentCard
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 10)
                }
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.medium, .large])
        // ✅ impede a sheet de “crescer” agressivamente por mudança de conteúdo; rola por dentro quando necessário
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.hidden)
        .onAppear {
            Task { await loadInvitesIfPossible() }
        }
        .alert("Erro", isPresented: $vm.showInviteErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.inviteErrorMessage ?? "Ocorreu um erro.")
        }
        .alert("Sucesso", isPresented: $vm.showInviteSuccessAlert) {
            Button("OK", role: .cancel) {}
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

                if !inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { inviteEmail = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )

            Button {
                Task {
                    guard let teacherId = session.uid, !teacherId.isEmpty else {
                        vm.setInviteError("Não foi possível identificar o professor logado.")
                        return
                    }
                    await vm.sendInviteByEmail(teacherId: teacherId, studentEmail: inviteEmail)
                    await loadInvitesIfPossible()
                }
            } label: {
                HStack {
                    Spacer()
                    if vm.isInvitesLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Enviar convite")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Spacer()
                }
                .foregroundColor(.white.opacity(0.92))
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.18)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.30), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(vm.isInvitesLoading || inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Text("O aluno só aparecerá na sua lista após aceitar o convite no app.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private var invitesSentCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("CONVITES ENVIADOS")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Spacer()

                Button {
                    Task { await loadInvitesIfPossible() }
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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
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
                        await vm.cancelInvite(inviteId: id)
                        await loadInvitesIfPossible()
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

    private func loadInvitesIfPossible() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else { return }
        await vm.loadInvites(teacherId: teacherId)
    }
}

