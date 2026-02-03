// TeacherLinkStudentView.swift — Tela para buscar e vincular alunos ao professor por categoria
import SwiftUI
import Combine

struct TeacherLinkStudentView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession
    @StateObject private var vm: TeacherLinkStudentViewModel

    private let contentMaxWidth: CGFloat = 380

    // Busca e estado de diálogo de categoria
    @State private var searchText: String = ""
    @State private var studentPendingLink: StudentLinkItem? = nil
    @State private var showCategoryDialog: Bool = false
    @State private var selectedLinkCategory: TreinoTipo = .crossfit

    init(
        path: Binding<[AppRoute]>,
        category: TreinoTipo,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.category = category
        _vm = StateObject(wrappedValue: TeacherLinkStudentViewModel(repository: repository))
    }

    // Corpo principal com busca, lista e confirmação de vínculo
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

                        controlsCard

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
                        selectedCategory: category,
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
                Text("Vincular aluno")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await initialLoadIfNeeded()
        }
        .alert("Erro", isPresented: $vm.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "Ocorreu um erro.")
        }
        .alert("Sucesso", isPresented: $vm.showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.successMessage ?? "Aluno vinculado.")
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
            Text(dialogMessageText())
        }
    }

    // Header explicando o fluxo de vínculo (agora: pedidos recebidos)
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pedidos recebidos de vínculo.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Text("Ao clicar em Vincular, selecione a categoria (Crossfit, Academia ou Treinos em casa).")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Card com filtro e busca
    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("FILTRO")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            HStack(spacing: 10) {
                chip(title: "Todos", isSelected: true) { /* fixo */ }
            }

            searchField
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.35))

            TextField("Buscar por nome...", text: $searchText)
                .foregroundColor(.white.opacity(0.92))
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    searchText = ""
                } label: {
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
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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

    // Conteúdo: lista de pedidos pendentes
    private var contentCard: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                loadingView
            } else if vm.items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private var listView: some View {
        let list = filteredItems()

        return VStack(spacing: 0) {
            if list.isEmpty {
                VStack(spacing: 10) {
                    Text("Nenhum aluno encontrado")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))

                    Text("Tente mudar a busca.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 10)
            } else {
                ForEach(Array(list.enumerated()), id: \.offset) { idx, item in
                    row(item: item)

                    if idx < list.count - 1 {
                        innerDivider(leading: 54)
                    }
                }
            }
        }
    }

    private func row(item: StudentLinkItem) -> some View {
        Button {
            studentPendingLink = item
            selectedLinkCategory = .crossfit
            showCategoryDialog = true
        } label: {
            HStack(spacing: 14) {

                StudentAvatarView(base64: item.photoBase64, size: 28)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {

                    Text(item.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))

                    if let text = categoryTextForItem(item) {
                        Text("Categoria: \(text)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    } else if !item.studentEmail.isEmpty {
                        Text(item.studentEmail)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }

                Spacer()

                Text("Vincular")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.90))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func categoryTextForItem(_ item: StudentLinkItem) -> String? {
        if let focus = item.focusArea, let cat = mapStringToTreinoTipo(focus) {
            return cat.displayName
        }
        if let def = item.defaultCategory, let cat = mapStringToTreinoTipo(def) {
            return cat.displayName
        }
        return nil
    }

    private func mapStringToTreinoTipo(_ rawOpt: String) -> TreinoTipo? {
        let raw = rawOpt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando pedidos...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhuma solicitação pendente")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Quando um aluno solicitar vínculo por e-mail, ele aparecerá aqui.")
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

    // Lógica de carregamento e confirmação de vínculo
    private func initialLoadIfNeeded() async {
        guard vm.items.isEmpty && !vm.isLoading else { return }

        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setError("Não foi possível identificar o professor logado.")
            return
        }

        await vm.loadPendingRequests(teacherId: teacherId)
    }

    private func filteredItems() -> [StudentLinkItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return vm.items
            .filter { item in
                if q.isEmpty { return true }
                return item.name.lowercased().contains(q)
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private func dialogMessageText() -> String {
        guard let item = studentPendingLink else { return "Selecione uma categoria." }
        return "Aluno: \(item.name)\nEscolha a categoria para vincular."
    }

    private func confirmLink(_ chosen: TreinoTipo) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setError("Não foi possível identificar o professor logado.")
            studentPendingLink = nil
            return
        }
        guard let item = studentPendingLink else { return }

        selectedLinkCategory = chosen

        await vm.approveRequestAndLinkStudent(
            teacherId: teacherId,
            requestId: item.requestId,
            studentId: item.studentId,
            category: chosen.rawValue
        )

        studentPendingLink = nil
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

@MainActor
final class TeacherLinkStudentViewModel: ObservableObject {

    @Published private(set) var items: [StudentLinkItem] = []
    @Published private(set) var isLoading: Bool = false

    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false

    @Published var successMessage: String? = nil
    @Published var showSuccessAlert: Bool = false

    private let repository: FirestoreRepository

    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    // ✅ Agora: carrega SOMENTE pedidos pendentes (alunos que solicitaram vínculo)
    func loadPendingRequests(teacherId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let requests = try await repository.getPendingLinkRequestsForTeacher(teacherId: teacherId)

            let results = try await withThrowingTaskGroup(of: StudentLinkItem?.self) { group in
                for req in requests {
                    group.addTask {
                        let sid = req.studentId.trimmingCharacters(in: .whitespacesAndNewlines)

                        var name: String = "Aluno"
                        var focusArea: String? = nil
                        var defaultCategory: String? = nil
                        var photoBase64: String? = nil

                        if !sid.isEmpty, let u = try await self.repository.getUser(uid: sid) {
                            name = u.name
                            focusArea = u.focusArea
                            defaultCategory = u.defaultCategory
                            photoBase64 = u.photoBase64
                        } else {
                            let email = req.studentEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !email.isEmpty { name = email }
                        }

                        let rid = req.id ?? ""
                        guard !rid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

                        return StudentLinkItem(
                            requestId: rid,
                            studentId: req.studentId,
                            studentEmail: req.studentEmail,
                            name: name,
                            photoBase64: photoBase64,
                            focusArea: focusArea,
                            defaultCategory: defaultCategory
                        )
                    }
                }

                var collected: [StudentLinkItem] = []
                for try await item in group {
                    if let item { collected.append(item) }
                }
                return collected
            }

            self.items = results

        } catch {
            setError((error as NSError).localizedDescription)
        }
    }

    // ✅ Aprova o pedido + vincula na categoria (mantém o padrão atual teacher_students)
    func approveRequestAndLinkStudent(
        teacherId: String,
        requestId: String,
        studentId: String,
        category: String
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.approveLinkRequestAndLinkStudent(
                teacherId: teacherId,
                requestId: requestId,
                studentId: studentId,
                category: category
            )

            successMessage = "Aluno vinculado com sucesso."
            showSuccessAlert = true

            await loadPendingRequests(teacherId: teacherId)

        } catch {
            setError((error as NSError).localizedDescription)
        }
    }

    func setError(_ msg: String) {
        errorMessage = msg
        showErrorAlert = true
    }
}

// Modelo simplificado de aluno para vínculo (agora baseado em REQUEST)
struct StudentLinkItem: Identifiable, Hashable {

    // Identidade do item na lista = id do pedido
    var id: String { requestId }

    let requestId: String
    let studentId: String
    let studentEmail: String

    let name: String
    let photoBase64: String?
    let focusArea: String?
    let defaultCategory: String?
}
