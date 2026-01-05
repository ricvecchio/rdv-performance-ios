import SwiftUI
import FirebaseAuth

// MARK: - Professor: Feedbacks do Aluno
struct TeacherFeedbacksView: View {

    @Binding var path: [AppRoute]
    let student: AppUser
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession

    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    @State private var feedbacks: [StudentFeedbackFS] = []

    @State private var newFeedbackText: String = ""
    @State private var showPasswordDummy: Bool = false

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
                            listCard
                            formCard

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
                    kind: .teacherHomeAlunoSobrePerfil(
                        selectedCategory: category,
                        isHomeSelected: false,
                        isAlunoSelected: true,
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
                Text("Feedbacks")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    Task { await loadFeedbacks() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                // ✅ AJUSTE SOLICITADO:
                // Avatar do cabeçalho agora segue o mesmo padrão do AboutView (foto real atual do usuário).
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await loadFeedbacks() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aluno: \(student.name)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))

            Text("Categoria: \(category.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text("Registre feedbacks e acompanhe o histórico.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("HISTÓRICO")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Spacer()

                if isLoading {
                    ProgressView().tint(.white)
                }
            }

            if feedbacks.isEmpty {
                Text("Nenhum feedback registrado ainda.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(feedbacks.enumerated()), id: \.offset) { idx, fb in
                        feedbackRow(fb)
                        if idx < feedbacks.count - 1 { innerDivider(leading: 16) }
                    }
                }
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

    private func feedbackRow(_ fb: StudentFeedbackFS) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 14))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(fb.text)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.80))

                    if let date = fb.createdAt {
                        Text(formatDate(date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }

                Spacer()
            }
        }
        .padding(.vertical, 12)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("NOVO FEEDBACK")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            VStack(alignment: .leading, spacing: 8) {
                Text("Texto")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))

                TextEditor(text: $newFeedbackText)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white.opacity(0.92))
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            }

            Divider().background(Theme.Colors.divider)

            Button { Task { await saveFeedback() } } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Salvar")
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
            .disabled(isSaving || isLoading)
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

    // MARK: - Actions

    private func loadFeedbacks() async {
        errorMessage = nil
        successMessage = nil

        guard session.isLoggedIn && session.isTrainer else {
            errorMessage = "Apenas professor pode acessar feedbacks."
            return
        }

        guard let sid = student.id, !sid.isEmpty else {
            errorMessage = "Aluno inválido: id não encontrado."
            return
        }

        guard let teacherId = Auth.auth().currentUser?.uid, !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let list = try await FirestoreRepository.shared.getStudentFeedbacks(
                teacherId: teacherId,
                studentId: sid,
                categoryRaw: category.rawValue,
                limit: 50
            )
            self.feedbacks = list
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }
    }

    private func saveFeedback() async {
        errorMessage = nil
        successMessage = nil

        guard session.isLoggedIn && session.isTrainer else {
            errorMessage = "Apenas professor pode salvar feedback."
            return
        }

        guard let sid = student.id, !sid.isEmpty else {
            errorMessage = "Aluno inválido: id não encontrado."
            return
        }

        guard let teacherId = Auth.auth().currentUser?.uid, !teacherId.isEmpty else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        let textTrim = newFeedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textTrim.isEmpty else {
            errorMessage = "Digite um feedback antes de salvar."
            return
        }

        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await FirestoreRepository.shared.createStudentFeedback(
                teacherId: teacherId,
                studentId: sid,
                categoryRaw: category.rawValue,
                text: textTrim
            )

            newFeedbackText = ""
            successMessage = "Feedback salvo com sucesso."
            await loadFeedbacks()

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy • HH:mm"
        return f.string(from: date)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

