import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TeacherWorkoutTemplatesView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    private let contentMaxWidth: CGFloat = 380

    @State private var templates: [WorkoutTemplateFS] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    @State private var isAddSheetPresented: Bool = false

    // ✅ Determina qual sheet de criação abrir baseado na categoria
    private var destinationSheet: AppRoute? {
        switch category {
        case .crossfit:
            return .createCrossfitWOD(
                category: category,
                sectionKey: sectionKey,
                sectionTitle: sectionTitle
            )
        case .academia:
            return .createTreinoAcademia(
                category: category,
                sectionKey: sectionKey,
                sectionTitle: sectionTitle
            )
        default:
            // Fallback para treinos em casa ou outras categorias
            return .createTreinoCasa(
                category: category,
                sectionKey: sectionKey,
                sectionTitle: sectionTitle
            )
        }
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
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            header

                            addButtonRow

                            contentCard

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
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
                    .lineLimit(1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadTemplates() }
        .onAppear { Task { await loadTemplates() } }
        .background(NavigationBarNoHairline())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Todos os treinos cadastrados nessa seção.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addButtonRow: some View {
        HStack(spacing: 10) {
            Button {
                if let route = destinationSheet {
                    path.append(route)
                }
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Novo Treino")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.green.opacity(0.16)))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    private var contentCard: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if templates.isEmpty {
                emptyView
            } else {
                templatesList
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

    private var templatesList: some View {
        VStack(spacing: 0) {
            ForEach(templates.indices, id: \.self) { idx in
                let t = templates[idx]

                templateRow(template: t)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openTemplateDetails(template: t)
                    }

                if idx < templates.count - 1 {
                    innerDivider(leading: 14)
                }
            }
        }
    }

    private func templateRow(template t: WorkoutTemplateFS) -> some View {
        HStack(spacing: 12) {

            iconForCategory

            VStack(alignment: .leading, spacing: 4) {
                Text(t.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)

                Text(t.description.isEmpty ? "Sem descrição" : t.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                // ✅ Corrigido: desempacotando o id opcional
                if let templateId = t.id {
                    Button(role: .destructive) {
                        Task { await deleteTemplate(templateId: templateId) }
                    } label: {
                        Label("Remover", systemImage: "trash.fill")
                    }
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

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var iconForCategory: some View {
        switch category {
        case .crossfit:
            return Image(systemName: "flame.fill")
                .foregroundColor(.orange.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)
        case .academia:
            return Image(systemName: "dumbbell.fill")
                .foregroundColor(.blue.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)
        default:
            // Fallback para treinos em casa
            return Image(systemName: "house.fill")
                .foregroundColor(.green.opacity(0.85))
                .font(.system(size: 16))
                .frame(width: 26)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Carregando...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("Nenhum treino cadastrado")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Toque em \"Novo Treino\" para começar a criar.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 10)
    }

    private func messageCard(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .yellow.opacity(0.85) : .green.opacity(0.85))

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func innerDivider(leading: CGFloat) -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, leading)
    }

    private func openTemplateDetails(template: WorkoutTemplateFS) {
        // Aqui você pode adicionar navegação para detalhes do template se necessário
    }

    // MARK: - Firestore

    private func loadTemplates() async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            templates = []
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let snap = try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("workoutTemplates")
                .whereField("category", isEqualTo: category.rawValue)
                .whereField("sectionKey", isEqualTo: sectionKey)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            let parsed: [WorkoutTemplateFS] = snap.documents.compactMap { doc in
                try? doc.data(as: WorkoutTemplateFS.self)
            }

            templates = parsed
        } catch {
            templates = []
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTemplate(templateId: String) async {
        errorMessage = nil

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await Firestore.firestore()
                .collection("teachers")
                .document(teacherId)
                .collection("workoutTemplates")
                .document(templateId)
                .delete()

            await loadTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
