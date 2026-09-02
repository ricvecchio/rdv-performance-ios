// StudentFeedbacksView.swift — Lista de feedbacks recebidos pelo aluno para uma categoria
import SwiftUI
import FirebaseAuth

struct StudentFeedbacksView: View {

    @Binding var path: [AppRoute]
    let category: TreinoTipo

    @EnvironmentObject private var session: AppSession

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var feedbacks: [StudentFeedbackFS] = []
    @State private var teachersById: [String: AppUser] = [:]

    private let contentMaxWidth: CGFloat = 380

    // Corpo principal com header, lista e footer
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Feedbacks")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
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

    // Header de contexto com categoria
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aqui você vê os feedbacks enviados pelo seu treinador.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Card com lista de feedbacks
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
                            Text(teachersById[fb.teacherId]?.name ?? "Professor")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))

                            Text(fb.text)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.75))

                            if let date = fb.createdAt {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                    Text(formatDate(date))
                                }
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

    // Mensagem de erro/aviso estilizada
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

    // Carrega feedbacks do Firestore
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
            let loadedFeedbacks = try await FirestoreRepository.shared.getFeedbacksForStudent(
                studentId: sid,
                categoryRaw: category.rawValue,
                limit: 50
            )
            let teacherIds = Array(Set(loadedFeedbacks.map(\.teacherId).filter { !$0.isEmpty }))
            teachersById = try await FirestoreRepository.shared.getUsers(byIds: teacherIds)
            feedbacks = loadedFeedbacks
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    // Formata data para exibição
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
