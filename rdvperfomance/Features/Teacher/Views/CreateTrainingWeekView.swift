
import SwiftUI
import FirebaseAuth

// MARK: - Professor: Criar Semana (training_weeks)
struct CreateTrainingWeekView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession

    @State private var weekTitle: String = ""
    @State private var showPasswordDummy: Bool = false // ✅ exigido pelo UnderlineTextField

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

                // ✅ Rodapé do professor no padrão do app
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
            // ✅ Voltar (padrão do app)
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            // ✅ Título central
            ToolbarItem(placement: .principal) {
                Text("Publicar semana")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            // ✅ Perfil
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Publicar semana")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white.opacity(0.95))

            Text("Categoria: \(category.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text("Preencha o título e publique. Depois você adiciona os dias.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Card do formulário (padrão Settings/Profile)
    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("DADOS DA SEMANA")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            UnderlineTextField(
                title: "Título da semana",
                text: $weekTitle,
                isSecure: false,
                showPassword: $showPasswordDummy,
                lineColor: Theme.Colors.divider,
                textColor: .white.opacity(0.92),
                placeholderColor: .white.opacity(0.55)
            )

            Divider()
                .background(Theme.Colors.divider)

            Button {
                Task { await publishWeek() }
            } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Publicar")
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

    // MARK: - Mensagens
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

    // MARK: - Actions
    private func publishWeek() async {
        errorMessage = nil
        successMessage = nil

        let titleTrim = weekTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrim.isEmpty else {
            errorMessage = "Informe o título da semana."
            return
        }

        guard session.userType == .TRAINER else {
            errorMessage = "Apenas professor pode publicar semanas."
            return
        }

        guard let teacherId = session.uid ?? Auth.auth().currentUser?.uid else {
            errorMessage = "Não foi possível identificar o professor logado."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // ✅ Aqui chamamos seu repository quando você já tiver o método implementado.
            // Por enquanto, deixo a navegação preparada (sem “tela branca”),
            // e você só precisa plugar o createWeek no FirestoreRepository.

            // Exemplo do que você vai implementar no repo:
            // let weekId = try await FirestoreRepository.shared.createTrainingWeek(
            //     teacherId: teacherId,
            //     category: category.firestoreKey,
            //     weekTitle: titleTrim
            // )

            // Placeholder de sucesso (até plugar o repo)
            let weekId = UUID().uuidString

            successMessage = "Semana publicada! Agora adicione os dias."
            weekTitle = ""

            // ✅ já manda para criar dia
            path.append(.createTrainingDay(weekId: weekId, category: category))

        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

