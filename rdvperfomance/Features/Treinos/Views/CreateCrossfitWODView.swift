import SwiftUI
import FirebaseAuth

/// Tela para criar um WOD (template) — semelhante ao CreateTrainingDayView, porém sem Data/Ordem/Nome do dia
struct CreateCrossfitWODView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo
    let sectionKey: String
    let sectionTitle: String

    @EnvironmentObject private var session: AppSession

    @State private var title: String = ""
    @State private var description: String = ""

    // ✅ mesmos blocos do "Criar dia" (inclui Cargas / Movimentos)
    @State private var blocks: [BlockDraft] = [
        BlockDraft(name: "Aquecimento", details: ""),
        BlockDraft(name: "Técnica", details: ""),
        BlockDraft(name: "WOD", details: ""),
        BlockDraft(name: "Cargas / Movimentos", details: "")
    ]

    @State private var showPasswordDummy: Bool = false

    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    private let contentMaxWidth: CGFloat = 380

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
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            header

                            trainingCard
                            blocksCard
                            saveButtonCard

                            if let err = errorMessage {
                                messageCard(text: err, isError: true)
                            }

                            if let ok = successMessage {
                                messageCard(text: ok, isError: false)
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
                Text("Adicionar WOD")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(category.displayName) • \(sectionTitle)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text("Crie um WOD para aparecer na lista desta seção.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Treino")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            UnderlineTextField(
                title: "Título do WOD",
                text: $title,
                isSecure: false,
                showPassword: $showPasswordDummy,
                lineColor: Theme.Colors.divider,
                textColor: .white.opacity(0.92),
                placeholderColor: .white.opacity(0.55)
            )

            Divider().background(Theme.Colors.divider)

            VStack(alignment: .leading, spacing: 6) {
                Text("Descrição")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))

                TextEditor(text: $description)
                    .foregroundColor(.white.opacity(0.92))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90)
                    .padding(10)
                    .background(Color.black.opacity(0.22))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var blocksCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Spacer()
                Button {
                    blocks.append(BlockDraft(name: "Novo bloco", details: ""))
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green.opacity(0.85))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }

            ForEach($blocks) { $b in
                VStack(alignment: .leading, spacing: 10) {

                    HStack {
                        Text(b.name.isEmpty ? "Sem nome" : b.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))

                        Spacer()

                        // ✅ Pode apagar qualquer bloco (inclusive "Cargas / Movimentos") — como você pediu
                        Button {
                            if let idx = blocks.firstIndex(where: { $0.id == b.id }) {
                                blocks.remove(at: idx)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.yellow.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    UnderlineTextField(
                        title: "",
                        text: $b.name,
                        isSecure: false,
                        showPassword: $showPasswordDummy,
                        lineColor: Theme.Colors.divider,
                        textColor: .white.opacity(0.92),
                        placeholderColor: .white.opacity(0.55)
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Detalhes")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))

                        TextEditor(text: $b.details)
                            .foregroundColor(.white.opacity(0.92))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 70)
                            .padding(10)
                            .background(Color.black.opacity(0.22))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }

                    Divider().background(Theme.Colors.divider)
                }
                .padding(.vertical, 6)
            }

            if blocks.isEmpty {
                Text("Nenhum bloco adicionado.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var saveButtonCard: some View {
        Button {
            Task { await saveTemplate() }
        } label: {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Salvar WOD")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.green.opacity(0.16))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
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

    private func saveTemplate() async {
        errorMessage = nil
        successMessage = nil

        guard session.userType == .TRAINER else {
            errorMessage = "Apenas professor pode adicionar WODs."
            return
        }

        let teacherId = (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Informe o título do WOD."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let payloadBlocks: [BlockFS] = blocks
                .filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { BlockFS(id: $0.id, name: $0.name, details: $0.details) }

            _ = try await FirestoreRepository.shared.createWorkoutTemplate(
                teacherId: teacherId,
                categoryRaw: category.rawValue,
                sectionKey: sectionKey,
                title: cleanTitle,
                description: description,
                blocks: payloadBlocks
            )

            // ✅ volta para lista (que recarrega no onAppear)
            pop()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

