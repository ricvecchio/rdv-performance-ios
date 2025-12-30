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

                // ✅ Rodapé do Professor no padrão do app
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

        // ✅ Cabeçalho padrão (igual HomeView)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
            Text("Alunos")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text("Selecione um aluno para ver as semanas de treino.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Filtro (padrão Settings/Profile)
    private var filterRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FILTRO")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .padding(.horizontal, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {

                    filterChip(
                        title: selectedCategory.displayNameFallback,
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

    // MARK: - Card padrão do app (igual Settings)
    private var contentCard: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                loadingView
            } else if let msg = vm.errorMessage {
                errorView(message: msg)
            } else if vm.students.isEmpty {
                emptyView
            } else {
                studentsList
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Lista (linhas dentro do card, sem mini-cards)
    private var studentsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.students.enumerated()), id: \.offset) { idx, student in
                Button {

                    guard let sid = student.id, !sid.isEmpty else {
                        vm.errorMessage = "Aluno inválido: id não encontrado."
                        return
                    }

                    let sname = student.name ?? "Aluno"
                    path.append(.studentAgenda(studentId: sid, studentName: sname))

                } label: {
                    HStack(spacing: 14) {

                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.green.opacity(0.85))
                            .frame(width: 28)

                        Text(student.name ?? "Aluno")
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

                if idx < vm.students.count - 1 {
                    innerDivider(leading: 54)
                }
            }
        }
    }

    // MARK: - Estados (cores padrão)
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
        VStack(spacing: 10) {
            Text("Nenhum aluno encontrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Ainda não há alunos nessa categoria.")
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

    // MARK: - Load
    private func loadStudents() async {
        guard let teacherId = session.uid else {
            vm.errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        let categoryKey = selectedCategory.firestoreCategoryKeyFallback
        await vm.loadStudents(teacherId: teacherId, category: categoryKey)
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

    func loadStudents(teacherId: String, category: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getStudentsForTeacher(teacherId: teacherId, category: category)
            self.students = result
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }
}

private extension TreinoTipo {
    var firestoreCategoryKeyFallback: String { String(describing: self).uppercased() }
    var displayNameFallback: String { String(describing: self).capitalized }
}

