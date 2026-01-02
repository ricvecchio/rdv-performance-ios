import SwiftUI

// MARK: - Tela (Professor): Perfil do Aluno (Detalhe)
struct TeacherStudentDetailView: View {

    @Binding var path: [AppRoute]

    let student: AppUser
    let category: TreinoTipo

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
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Cards

    private func headerCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Categoria do Treino")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

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

    private func progressCard() -> some View {
        let progress: Double = 0.0

        return VStack(alignment: .leading, spacing: 12) {

            Text("Progresso do Aluno")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))

            HStack {
                Text("\(Int(progress * 100))% completo")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
            }

            ProgressView(value: progress)
                .tint(.green.opacity(0.85))
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
                // TODO
            }

            actionButton(title: "Feedbacks", icon: "text.bubble.fill") {
                // TODO
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

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 16))

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.25))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
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
}

