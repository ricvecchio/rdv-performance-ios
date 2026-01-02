import SwiftUI
import Combine

struct TeacherStudentsListView: View {

    @Binding var path: [AppRoute]
    let selectedCategory: TreinoTipo

    @EnvironmentObject private var session: AppSession
    @StateObject private var vm: TeacherStudentsListViewModel

    @State private var filter: TreinoTipo? = nil
    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        selectedCategory: TreinoTipo,
        repository: FirestoreRepository = .shared
    ) {
        self._path = path
        self.selectedCategory = selectedCategory
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
        .onAppear {
            if filter == nil { filter = selectedCategory }
        }
        .task { await loadStudents() }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            // ✅ VOLTAR (padrão do app)
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

            // ✅ AÇÕES À DIREITA: Vincular + MiniProfile
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    path.append(.teacherLinkStudent(category: selectedCategory))
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                MiniProfileHeader(imageName: "rdv_eu", size: 38)
                    .background(Color.clear)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Selecione um aluno para ver detalhes e criar treinos.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Filtro
    private var filterRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FILTRO")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .padding(.horizontal, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {

                    filterChip(
                        title: selectedCategory.displayName,
                        isSelected: filter == selectedCategory
                    ) { filter = selectedCategory }

                    filterChip(
                        title: "Todos",
                        isSelected: filter == nil
                    ) { filter = nil }
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

    // MARK: - Card
    private var contentCard: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                loadingView
            } else if let msg = vm.errorMessage {
                errorView(message: msg)
            } else {
                let list = vm.filteredStudents(filter: filter)
                if list.isEmpty {
                    emptyView
                } else {
                    studentsList(list)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Lista
    private func studentsList(_ list: [AppUser]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.offset) { idx, student in
                Button {

                    guard let sid = student.id, !sid.isEmpty else {
                        vm.errorMessage = "Aluno inválido: id não encontrado."
                        return
                    }

                    path.append(.teacherStudentDetail(student, selectedCategory))

                } label: {
                    HStack(spacing: 14) {

                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.green.opacity(0.85))
                            .frame(width: 28)

                        Text(student.name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.92))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if idx < list.count - 1 {
                    innerDivider(leading: 54)
                }
            }
        }
    }

    // MARK: - Estados
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
                Task { await loadStudents() }
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

            Button {
                path.append(.teacherLinkStudent(category: selectedCategory))
            } label: {
                Text("Vincular aluno")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
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

    // MARK: - Load
    private func loadStudents() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.errorMessage = "Não foi possível identificar o professor logado."
            return
        }
        await vm.loadStudents(teacherId: teacherId, selectedCategory: selectedCategory)
    }

    // MARK: - Navigation
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

@MainActor
final class TeacherStudentsListViewModel: ObservableObject {

    @Published private(set) var students: [AppUser] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let repository: FirestoreRepository

    init(repository: FirestoreRepository) {
        self.repository = repository
    }

    func loadStudents(teacherId: String, selectedCategory: TreinoTipo) async {
        isLoading = true
        errorMessage = nil

        do {
            // Busca via teacher_students: teacherId + categories arrayContains
            let result = try await repository.getStudentsForTeacher(
                teacherId: teacherId,
                category: selectedCategory.rawValue
            )
            self.students = result
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }

    func filteredStudents(filter: TreinoTipo?) -> [AppUser] {
        guard let filter else { return students }
        let key = filter.rawValue.lowercased()
        return students.filter { ($0.defaultCategory ?? "").lowercased() == key }
    }
}

