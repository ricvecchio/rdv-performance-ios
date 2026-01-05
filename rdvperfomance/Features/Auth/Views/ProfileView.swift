import SwiftUI
import UIKit
import FirebaseAuth

// MARK: - ProfileView
struct ProfileView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    @AppStorage("profile_photo_data")
    private var profilePhotoBase64: String = ""

    private let repository: FirestoreRepository = .shared

    private var currentUid: String {
        (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Estado (por usuário)
    @State private var userName: String = ""
    @State private var unitName: String = ""          // aluno e professor
    @State private var isPlanActive: Bool = false     // aluno calcula / professor força true
    @State private var isLoading: Bool = false

    // ✅ Categoria do aluno (vinda do Firestore, com fallback)
    @State private var studentDefaultCategoryRaw: String = ""

    private var categoriaAtualAluno: TreinoTipo {
        let raw = studentDefaultCategoryRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let t = TreinoTipo(rawValue: raw), !raw.isEmpty {
            return t
        }
        return TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Check-ins (apenas aluno)
    @State private var checkinsConcluidos: Int = 0
    @State private var checkinsTotalSemana: Int = 0

    // Alert Trocar unidade (aluno e professor)
    @State private var showTrocarUnidadeAlert: Bool = false
    @State private var unidadeDraft: String = ""

    // Alert erro
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String? = nil

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

        // ✅ Trocar unidade (aluno e professor)
        .alert("Trocar unidade", isPresented: $showTrocarUnidadeAlert) {
            TextField("Ex.: CROSSFIT MURALHA", text: $unidadeDraft)

            Button("Cancelar", role: .cancel) { }

            Button("Salvar") {
                Task { await salvarUnidade() }
            }
        } message: {
            Text("Digite a unidade onde você treina. Se deixar em branco, a unidade será removida do perfil.")
        }

        // ✅ Erro
        .alert("Erro", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                showErrorAlert = false
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }

        // ✅ Recarrega quando mudar o usuário logado
        .task(id: currentUid) {
            await loadUserData()
        }
    }

    // MARK: - Footer
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

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - Helpers (foto)
    private var profileUIImage: UIImage? {
        guard !profilePhotoBase64.isEmpty else { return nil }
        guard let data = Data(base64Encoded: profilePhotoBase64) else { return nil }
        return UIImage(data: data)
    }

    @ViewBuilder
    private func profileAvatarView() -> some View {
        if let uiImage = profileUIImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image("rdv_user_default")
                .resizable()
                .scaledToFill()
        }
    }

    // MARK: - Load
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
            // ✅ Nome e unidade vêm do Firestore (sem hardcode)
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
                // ✅ Planos do aluno: Ativo se existir qualquer week vinculada
                isPlanActive = try await repository.hasAnyWeeksForStudent(studentId: uid)

                // ✅ Check-ins da semana em andamento
                await loadCheckinsSemanaEmAndamento(studentId: uid)
            } else {
                // ✅ Professor: Planos sempre Ativo e não tem check-ins
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

    // MARK: - Check-ins (apenas aluno)
    private func loadCheckinsSemanaEmAndamento(studentId: String) async {
        do {
            let weeks = try await repository.getWeeksForStudent(studentId: studentId, onlyPublished: true)

            let today = Date()
            let calendar = Calendar.current

            let currentWeek: TrainingWeekFS? = weeks.first(where: { w in
                guard let start = w.startDate, let end = w.endDate else { return false }
                let s = calendar.startOfDay(for: start)
                let e = calendar.startOfDay(for: end)
                let t = calendar.startOfDay(for: today)
                return (t >= s && t <= e)
            })

            guard let week = currentWeek, let weekId = week.id else {
                checkinsConcluidos = 0
                checkinsTotalSemana = 0
                return
            }

            let days = try await repository.getDaysForWeek(weekId: weekId)
            let total = days.count

            guard total > 0 else {
                checkinsConcluidos = 0
                checkinsTotalSemana = 0
                return
            }

            let statusMap = try await repository.getDayStatusMap(weekId: weekId, studentId: studentId)
            let dayIds = Set(days.compactMap { $0.id })

            let concluidos = statusMap.filter { pair in
                pair.value == true && dayIds.contains(pair.key)
            }.count

            checkinsConcluidos = concluidos
            checkinsTotalSemana = total

        } catch {
            checkinsConcluidos = 0
            checkinsTotalSemana = 0
        }
    }

    // MARK: - Unidade (aluno e professor)
    private func openTrocarUnidade() {
        unidadeDraft = unitName
        showTrocarUnidadeAlert = true
    }

    private func salvarUnidade() async {
        let uid = currentUid
        guard !uid.isEmpty else { return }

        let trimmed = unidadeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        unitName = trimmed

        do {
            // ✅ Salva por usuário; se vazio, remove o campo no Firestore
            try await repository.setStudentUnitName(uid: uid, unitName: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Planos
    private var planoStatusTexto: String { isPlanActive ? "Ativo" : "Inativo" }
    private var planoStatusForeground: Color { isPlanActive ? Color.green.opacity(0.9) : Color.red.opacity(0.95) }
    private var planoStatusBackground: Color { isPlanActive ? Color.green.opacity(0.16) : Color.red.opacity(0.18) }

    // MARK: - UI Cards
    private func profileCard() -> some View {
        VStack(spacing: 10) {

            profileAvatarView()
                .frame(width: 92, height: 92)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

            // ✅ ID removido (para aluno e professor)

            // ✅ Nome sem hardcode
            Text(userName.isEmpty ? " " : userName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)

            // ✅ Unidade para ambos (aluno e professor)
            Text(unitName.isEmpty ? " " : unitName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func optionsCard() -> some View {
        VStack(spacing: 0) {

            // ✅ Aluno e Professor podem trocar unidade
            optionRow(icon: "ruler", title: "Trocar unidade", trailing: .chevron) {
                openTrocarUnidade()
            }
            divider()

            // ✅ Planos: aluno calcula / professor sempre ativo
            optionRow(
                icon: "crown.fill",
                title: "Planos",
                trailing: .coloredBadge(planoStatusTexto, fg: planoStatusForeground, bg: planoStatusBackground)
            )

            // ✅ Check-ins só para aluno
            if session.userType == .STUDENT {
                divider()
                optionRow(
                    icon: "checkmark.seal.fill",
                    title: "Check-ins na semana",
                    trailing: .text("\(checkinsConcluidos)/\(checkinsTotalSemana)")
                )

                // ✅ NOVO: Mensagens e Feedbacks para o aluno
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

    // MARK: - Logout
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

