import SwiftUI
import Combine
import FirebaseFirestore

// MARK: - Professor: Vincular Aluno
struct TeacherLinkStudentView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = TeacherLinkStudentViewModel()

    private let contentMaxWidth: CGFloat = 380

    @State private var filterOnlyCategory: Bool = true
    @State private var searchText: String = ""

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
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
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
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vincule alunos ao seu perfil para a categoria \(category.displayName).")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))

            Text("Depois disso, eles aparecerão na sua lista de alunos.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls
    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("FILTROS")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            HStack(spacing: 10) {

                chip(
                    title: "Somente \(category.displayName)",
                    isSelected: filterOnlyCategory
                ) { filterOnlyCategory = true }

                chip(
                    title: "Todos",
                    isSelected: !filterOnlyCategory
                ) { filterOnlyCategory = false }
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

    // MARK: - Content Card
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

                    Text("Tente mudar o filtro ou a busca.")
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
            Task { await link(item: item) }
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

                    if let cat = item.defaultCategory, !cat.isEmpty {
                        Text("Categoria: \(cat)")
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

    // MARK: - Logic
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
                if filterOnlyCategory {
                    let cat = (item.defaultCategory ?? "").lowercased()
                    return cat == category.rawValue.lowercased()
                }
                return true
            }
            .filter { item in
                if q.isEmpty { return true }
                return item.name.lowercased().contains(q)
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private func link(item: StudentLinkItem) async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.setError("Não foi possível identificar o professor logado.")
            return
        }
        await vm.linkStudent(
            teacherId: teacherId,
            studentId: item.id,
            category: category.rawValue
        )
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - ViewModel
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
                let defaultCategory = data["defaultCategory"] as? String
                return StudentLinkItem(
                    id: doc.documentID,
                    name: name,
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

// MARK: - DTO leve (não depende do AppUser)
struct StudentLinkItem: Identifiable, Hashable {
    let id: String
    let name: String
    let defaultCategory: String?
}
