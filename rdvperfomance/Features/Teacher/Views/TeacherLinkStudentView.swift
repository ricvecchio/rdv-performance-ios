// TeacherLinkStudentView.swift — Tela para buscar e vincular alunos ao professor por categoria
import SwiftUI
import Combine
import FirebaseFirestore

struct TeacherLinkStudentView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = TeacherLinkStudentViewModel()

    private let contentMaxWidth: CGFloat = 380

    // Busca e estado de diálogo de categoria
    @State private var searchText: String = ""
    @State private var studentPendingLink: StudentLinkItem? = nil
    @State private var showCategoryDialog: Bool = false
    @State private var selectedLinkCategory: TreinoTipo = .crossfit

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
                MiniProfileHeader(imageName: "rdv_user_default", size: 38)
                    .background(Color.clear)
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

    // Header explicando o fluxo de vínculo
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vincule alunos ao seu perfil.")
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

    // Conteúdo: lista de possíveis alunos a vincular
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

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.green.opacity(0.85))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {

                    Text(item.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))

                    // ✅ CORREÇÃO: mostra a categoria do cadastro (focusArea), e faz fallback para defaultCategory só se precisar
                    if let text = categoryTextForItem(item) {
                        Text("Categoria: \(text)")
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

    // ✅ Converte FocusArea/defaultCategory para texto amigável
    private func categoryTextForItem(_ item: StudentLinkItem) -> String? {
        // prioridade: focusArea (cadastro real)
        if let focus = item.focusArea, let cat = mapStringToTreinoTipo(focus) {
            return cat.displayName
        }
        // fallback: defaultCategory (caso dados antigos)
        if let def = item.defaultCategory, let cat = mapStringToTreinoTipo(def) {
            return cat.displayName
        }
        return nil
    }

    private func mapStringToTreinoTipo(_ rawOpt: String) -> TreinoTipo? {
        let raw = rawOpt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !raw.isEmpty else { return nil }

        // focusArea (CROSSFIT / GYM / HOME)
        if raw == FocusAreaDTO.CROSSFIT.rawValue.lowercased() { return .crossfit }
        if raw == FocusAreaDTO.GYM.rawValue.lowercased() { return .academia }
        if raw == FocusAreaDTO.HOME.rawValue.lowercased() { return .emCasa }

        // defaultCategory (crossfit / academia / emCasa etc.)
        if raw.contains("cross") { return .crossfit }
        if raw.contains("gym") || raw.contains("academ") { return .academia }
        if raw.contains("casa") || raw.contains("home") { return .emCasa }

        // TreinoTipo.rawValue (caso use)
        if raw == TreinoTipo.crossfit.rawValue.lowercased() { return .crossfit }
        if raw == TreinoTipo.academia.rawValue.lowercased() { return .academia }
        if raw == TreinoTipo.emCasa.rawValue.lowercased() { return .emCasa }

        return nil
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

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhum aluno cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Cadastre alunos no app para aparecerem aqui.")
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

        await vm.loadAllStudents(teacherId: teacherId)
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

        await vm.linkStudent(
            teacherId: teacherId,
            studentId: item.id,
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

    private let db = Firestore.firestore()

    func loadAllStudents(teacherId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snap = try await db.collection("users")
                .whereField("userType", isEqualTo: "STUDENT")
                .getDocuments()

            self.items = snap.documents.compactMap { doc in
                let data = doc.data()
                let name = (data["name"] as? String) ?? "Sem nome"

                // ✅ Categoria correta do cadastro
                let focusArea = data["focusArea"] as? String

                // fallback legado
                let defaultCategory = data["defaultCategory"] as? String

                return StudentLinkItem(
                    id: doc.documentID,
                    name: name,
                    focusArea: focusArea,
                    defaultCategory: defaultCategory
                )
            }

        } catch {
            setError((error as NSError).localizedDescription)
        }
    }

    func linkStudent(teacherId: String, studentId: String, category: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let existing = try await db.collection("teacher_students")
                .whereField("teacherId", isEqualTo: teacherId)
                .whereField("studentId", isEqualTo: studentId)
                .limit(to: 1)
                .getDocuments()

            if let doc = existing.documents.first {
                try await db.collection("teacher_students")
                    .document(doc.documentID)
                    .updateData([
                        "categories": FieldValue.arrayUnion([category]),
                        "updatedAt": FieldValue.serverTimestamp()
                    ])
            } else {
                let relDoc: [String: Any] = [
                    "teacherId": teacherId,
                    "studentId": studentId,
                    "categories": [category],
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                _ = try await db.collection("teacher_students").addDocument(data: relDoc)
            }

            successMessage = "Aluno vinculado com sucesso."
            showSuccessAlert = true

        } catch {
            setError((error as NSError).localizedDescription)
        }
    }

    func setError(_ msg: String) {
        errorMessage = msg
        showErrorAlert = true
    }
}

// Modelo simplificado de aluno para vínculo
struct StudentLinkItem: Identifiable, Hashable {
    let id: String
    let name: String

    // ✅ novo: categoria do cadastro (RegisterStudentView)
    let focusArea: String?

    // fallback legado
    let defaultCategory: String?
}

