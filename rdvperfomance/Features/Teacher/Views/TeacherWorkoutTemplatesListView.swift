import SwiftUI
import FirebaseAuth

struct TeacherWorkoutTemplatesListView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    private let contentMaxWidth: CGFloat = 380
    private let repo: FirestoreRepository = .shared

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var items: [WorkoutTemplateFS] = []

    @State private var showCreateDialog: Bool = false
    @State private var newTitle: String = ""
    @State private var newDesc: String = ""

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
                    VStack(alignment: .leading, spacing: 14) {

                        header

                        contentCard

                        Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                FooterBar(
                    path: $path,
                    kind: .teacherHomeAlunosSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunosSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
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
                Text(sectionTitle)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newTitle = ""
                    newDesc = ""
                    showCreateDialog = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
        .alert("Novo treino", isPresented: $showCreateDialog) {
            TextField("Título", text: $newTitle)
            TextField("Descrição (opcional)", text: $newDesc)

            Button("Cancelar", role: .cancel) { }

            Button("Salvar") {
                Task { await createTemplate() }
            }
        } message: {
            Text("Este treino ficará disponível em “Meus Treinos” para anexar nos dias/semanas.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categoria: \(category.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text("Seção: \(sectionTitle)")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if let err = errorMessage {
                errorView(err)
            } else if items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var listView: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                HStack(spacing: 12) {

                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.green.opacity(0.85))
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))

                        if !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(item.description)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.55))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)

                if idx < items.count - 1 {
                    Divider().background(Theme.Colors.divider).padding(.leading, 54)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando treinos...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Text("Ops! Não foi possível carregar.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(msg)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Button {
                Task { await load() }
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
            Text("Nenhum treino cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Toque em + para criar seu primeiro treino.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            items = []
            return
        }

        do {
            items = try await repo.getWorkoutTemplates(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey
            )
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
    }

    private func createTemplate() async {
        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else { return }

        let titleTrim = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrim.isEmpty else { return }

        do {
            _ = try await repo.createWorkoutTemplate(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey,
                title: titleTrim,
                description: newDesc
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
