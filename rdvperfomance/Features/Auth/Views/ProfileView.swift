// Tela de perfil com informações do usuário e opções
import SwiftUI
import UIKit
import FirebaseAuth

struct ProfileView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    // Retorna categoria de treino selecionada pelo professor
    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    @AppStorage("profile_photo_data")
    private var profilePhotoBase64: String = ""

    private let repository: FirestoreRepository = .shared

    // Retorna UID do usuário atualmente logado
    private var currentUid: String {
        (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @State private var userName: String = ""
    @State private var unitName: String = ""
    @State private var isPlanActive: Bool = false
    @State private var isLoading: Bool = false

    @State private var studentDefaultCategoryRaw: String = ""

    // Retorna categoria padrão do aluno baseada nos dados carregados
    private var categoriaAtualAluno: TreinoTipo {
        let raw = studentDefaultCategoryRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let t = TreinoTipo(rawValue: raw), !raw.isEmpty {
            return t
        }
        return TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    @State private var checkinsConcluidos: Int = 0
    @State private var checkinsTotalSemana: Int = 0

    @State private var showTrocarUnidadeAlert: Bool = false
    @State private var unidadeDraft: String = ""

    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String? = nil

    // Interface principal com cards, scroll e footer adaptado por tipo de usuário
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

                        VStack(spacing: 16) {
                            profileCard()
                            optionsCard()
                            logoutButton()
                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                footerForUser()
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
                Text("Perfil")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    path.append(.configuracoes)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Trocar unidade", isPresented: $showTrocarUnidadeAlert) {
            TextField("Ex.: CROSSFIT MURALHA", text: $unidadeDraft)

            Button("Cancelar", role: .cancel) { }

            Button("Salvar") {
                Task { await salvarUnidade() }
            }
        } message: {
            Text("Digite a unidade onde você treina. Se deixar em branco, a unidade será removida do perfil.")
        }
        .alert("Erro", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                showErrorAlert = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task(id: currentUid) {
            await loadUserData()
        }
    }

    // Renderiza footer baseado no tipo de usuário (aluno ou professor)
    @ViewBuilder
    private func footerForUser() -> some View {
        if session.userType == .STUDENT {
            FooterBar(
                path: $path,
                kind: .agendaSobrePerfil(
                    isAgendaSelected: false,
                    isSobreSelected: false,
                    isPerfilSelected: true
                )
            )
        } else {
            FooterBar(
                path: $path,
                kind: .teacherHomeAlunosSobrePerfil(
                    selectedCategory: categoriaAtualProfessor,
                    isHomeSelected: false,
                    isAlunosSelected: false,
                    isSobreSelected: false,
                    isPerfilSelected: true
                )
            )
        }
    }

    // Remove última rota da navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Carrega informações do usuário e status do plano do Firestore
    private func loadUserData() async {
        let uid = currentUid
        guard !uid.isEmpty else {
            userName = ""
            unitName = ""
            isPlanActive = false
            studentDefaultCategoryRaw = ""
            checkinsConcluidos = 0
            checkinsTotalSemana = 0
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if let user = try await repository.getUser(uid: uid) {
                userName = user.name
                unitName = (user.unitName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                studentDefaultCategoryRaw = (user.defaultCategory ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                userName = ""
                unitName = ""
                studentDefaultCategoryRaw = ""
            }

            if session.userType == .STUDENT {
                isPlanActive = try await repository.hasAnyWeeksForStudent(studentId: uid)
            } else {
                isPlanActive = true
                checkinsConcluidos = 0
                checkinsTotalSemana = 0
            }

        } catch {
            userName = ""
            unitName = ""
            studentDefaultCategoryRaw = ""
            isPlanActive = (session.userType != .STUDENT)
            checkinsConcluidos = 0
            checkinsTotalSemana = 0

            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // Abre modal para edição da unidade de treino
    private func openTrocarUnidade() {
        unidadeDraft = unitName
        showTrocarUnidadeAlert = true
    }

    // Persiste nova unidade de treino no Firestore
    private func salvarUnidade() async {
        let uid = currentUid
        guard !uid.isEmpty else { return }

        let trimmed = unidadeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        unitName = trimmed

        do {
            try await repository.setStudentUnitName(uid: uid, unitName: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private var planoStatusTexto: String { isPlanActive ? "Ativo" : "Inativo" }
    private var planoStatusForeground: Color { isPlanActive ? Color.green.opacity(0.9) : Color.red.opacity(0.95) }
    private var planoStatusBackground: Color { isPlanActive ? Color.green.opacity(0.16) : Color.red.opacity(0.18) }

    // Exibe card com avatar, nome do usuário e unidade de treino
    private func profileCard() -> some View {
        VStack(spacing: 10) {

            HeaderAvatarView(size: 92)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

            Text(userName.isEmpty ? " " : userName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)

            Text(unitName.isEmpty ? " " : unitName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Lista opções do perfil (unidade, planos, check-ins, mensagens, feedbacks)
    private func optionsCard() -> some View {
        VStack(spacing: 0) {

            optionRow(icon: "ruler", title: "Trocar unidade", trailing: .chevron) {
                openTrocarUnidade()
            }
            divider()

            optionRow(
                icon: "crown.fill",
                title: "Planos",
                trailing: .coloredBadge(planoStatusTexto, fg: planoStatusForeground, bg: planoStatusBackground)
            )

            if session.userType == .STUDENT {
                divider()
                optionRow(icon: "envelope.fill", title: "Mensagens", trailing: .chevron) {
                    path.append(.studentMessages(category: categoriaAtualAluno))
                }

                divider()
                optionRow(icon: "text.bubble.fill", title: "Feedbacks", trailing: .chevron) {
                    path.append(.studentFeedbacks(category: categoriaAtualAluno))
                }
            }
        }
        .padding(.vertical, 8)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Linha divisória entre opções do menu
    private func divider() -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 56)
    }

    private enum Trailing {
        case chevron
        case text(String)
        case badge(String)
        case coloredBadge(String, fg: Color, bg: Color)
    }

    // Renderiza linha de opção com ícone, título e indicador à direita
    private func optionRow(
        icon: String,
        title: String,
        trailing: Trailing,
        onTap: (() -> Void)? = nil
    ) -> some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    optionRowContent(icon: icon, title: title, trailing: trailing)
                }
                .buttonStyle(.plain)
            } else {
                optionRowContent(icon: icon, title: title, trailing: trailing)
            }
        }
    }

    // Conteúdo visual da linha de opção
    private func optionRowContent(icon: String, title: String, trailing: Trailing) -> some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green.opacity(0.85))
                .frame(width: 28)

            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.95))

            Spacer()

            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))

            case .text(let value):
                Text(value)
                    .foregroundColor(.green.opacity(0.85))

            case .badge(let value):
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.16)))

            case .coloredBadge(let value, let fg, let bg):
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(fg)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(bg))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // Botão para deslogar usuário e retornar à tela de login
    private func logoutButton() -> some View {
        Button {
            session.logout()
            path.removeAll()
            path.append(.login)
        } label: {
            Text("Sair")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.28))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: Color.green.opacity(0.10), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

