import SwiftUI

// TeacherStudentDetailView — Detalhes do aluno para o professor
struct TeacherStudentDetailView: View {

    @Binding var path: [AppRoute]

    let student: AppUser
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380

    @State private var progress: Double = 0.0
    @State private var isLoadingProgress: Bool = false

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

                        VStack(spacing: 14) {

                            headerCard()
                            progressCard()
                            actionsCard()

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
                Text("Aluno")
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
            await loadProgress()
        }
    }

    // MARK: - Cards

    private func headerCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Categoria do Treino")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            // ✅ Agora essa categoria vem correta pela navegação (TeacherStudentsListView)
            Text(category.tituloOverlayImagem)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Divider()
                .background(Theme.Colors.divider)

            Text("Aluno")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            Text(student.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))

            Text("Plano: \(student.planType ?? "—")")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.70))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func progressCard() -> some View {

        let percent = Int((progress * 100.0).rounded())

        return VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Progresso do Aluno")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                if isLoadingProgress {
                    ProgressView().tint(.white)
                }
            }

            Text("\(percent)% completo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            ProgressView(value: progress)
                .tint(.green.opacity(0.85))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func actionsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Ações")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            actionButton(title: "Publicar Semana", icon: "square.and.pencil") {
                path.append(.createTrainingWeek(student: student, category: category))
            }

            actionButton(title: "Ver Agenda do Aluno", icon: "calendar") {
                openAgenda()
            }

            actionButton(title: "Enviar Mensagem", icon: "paperplane.fill") {
                path.append(.teacherSendMessage(student: student, category: category))
            }

            actionButton(title: "Feedbacks", icon: "text.bubble.fill") {
                path.append(.teacherFeedbacks(student: student, category: category))
            }

            actionButton(title: "Preview do Progresso", icon: "gamecontroller.fill") {
                path.append(.spriteDemo)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Helpers

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.green.opacity(0.85))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(14)
            .background(Color.black.opacity(0.25))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func openAgenda() {
        guard let sid = student.id, !sid.isEmpty else { return }
        path.append(.studentAgenda(studentId: sid, studentName: student.name))
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Carrega progresso geral do aluno
    private func loadProgress() async {
        guard session.userType == .TRAINER else { return }
        guard let sid = student.id, !sid.isEmpty else { return }

        isLoadingProgress = true
        defer { isLoadingProgress = false }

        do {
            let p = try await FirestoreRepository.shared.getStudentOverallProgress(studentId: sid)
            self.progress = Double(p.percent) / 100.0
        } catch {
            self.progress = 0.0
        }
    }
}

