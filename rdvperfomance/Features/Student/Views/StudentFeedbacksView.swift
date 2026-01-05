import SwiftUI
import FirebaseAuth

struct StudentFeedbacksView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var feedbacks: [StudentFeedbackFS] = []

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
                    kind: .agendaSobrePerfil(
                        isAgendaSelected: false,
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
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { Task { await load() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                MiniProfileHeader(imageName: "rdv_user_default", size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categoria: \(category.displayName)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))

            Text("Aqui você vê os feedbacks enviados pelo seu treinador.")
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
                Text("Nenhum feedback recebido ainda.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(feedbacks.enumerated()), id: \.offset) { idx, fb in
                        VStack(alignment: .leading, spacing: 6) {

                            Text(fb.text)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.75))

                            if let date = fb.createdAt {
                                Text(formatDate(date))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                        }
                        .padding(.vertical, 12)

                        if idx < feedbacks.count - 1 {
                            Divider()
                                .background(Theme.Colors.divider)
                                .padding(.leading, 16)
                        }
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

    private func load() async {
        errorMessage = nil

        guard session.isLoggedIn && session.isStudent else {
            errorMessage = "Apenas aluno pode acessar feedbacks."
            return
        }

        guard let sid = Auth.auth().currentUser?.uid, !sid.isEmpty else {
            errorMessage = "Não foi possível identificar o aluno logado."
            return
        }

        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            feedbacks = try await FirestoreRepository.shared.getFeedbacksForStudent(
                studentId: sid,
                categoryRaw: category.rawValue,
                limit: 50
            )
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
