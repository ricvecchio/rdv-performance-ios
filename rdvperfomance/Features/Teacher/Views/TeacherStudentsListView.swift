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

    // Corpo principal com header, filtro e lista
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
            filter = initialFilter
        }
        .task { await loadStudents() }
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

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
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

                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.green.opacity(0.85))
                        .frame(width: 28)

                    Text(student.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))

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
                    path.append(.teacherStudentDetail(student, selectedCategory))
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

    // Load: carrega alunos considerando filtro inicial
    private func loadStudents() async {
        guard let teacherId = session.uid, !teacherId.isEmpty else {
            vm.errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        if let initial = initialFilter {
            await vm.loadStudentsOnlyOneCategory(teacherId: teacherId, category: initial)
        } else {
            await vm.loadStudents(teacherId: teacherId)
        }
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
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
