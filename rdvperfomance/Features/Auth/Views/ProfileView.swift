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

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    @AppStorage("profile_photo_data")
    private var profilePhotoBase64: String = ""

    private let repository: FirestoreRepository = .shared

    private var currentUid: String {
        (Auth.auth().currentUser?.uid ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @State private var userName: String = ""
    @State private var unitName: String = ""
    @State private var isPlanActive: Bool = false
    @State private var isLoading: Bool = false

    @State private var studentDefaultCategoryRaw: String = ""

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

    @State private var showMeusIconesModal: Bool = false
    @State private var copiedIconName: String? = nil

    @State private var showPlanosModal: Bool = false
    @State private var planoSliderValue: Double = 0.0
    @State private var showConfirmacaoPro: Bool = false
    @State private var showSimulacaoOkAlert: Bool = false
    @State private var isConfirmingPro: Bool = false
    @State private var showCancelarPlanoConfirm: Bool = false
    @State private var isCancelingPlan: Bool = false

    private let treinoIcons = [
        "dumbbell",
        "figure.run",
        "figure.walk",
        "figure.strengthtraining.traditional",
        "heart.fill",
        "flame.fill",
        "bolt.fill",
        "stopwatch",
        "calendar",
        "checkmark.seal.fill",
        "chart.bar.fill",
        "person.2.fill",
        "figure.cross.training",
        "figure.cross.training.circle",
        "figure.flexibility",
        "figure.gymnastics",
        "figure.highintensity.intervaltraining",
        "figure.mixed.cardio",
        "figure.yoga",
        "figure.pilates",
        "figure.strengthtraining.functional",
        "figure.strengthtraining.functional.circle",
        "figure.cooldown",
        "figure.core.training",
        "figure.arms.open",
        "figure.stand",
        "figure.squat",
        "figure.lunge",
        "figure.rower",
        "figure.stair.stepper",
        "figure.outdoor.cycle",
        "figure.indoor.cycle",
        "figure.jumprope",
        "figure.hiking",
        "dumbbell.fill",
        "backpack.fill",
        "waterbottle.fill",
        "timer",
        "speedometer",
        "target",
        "scope",
        "line.diagonal.arrow",
        "arrow.triangle.2.circlepath",
        "lungs.fill",
        "waveform.path.ecg",
        "heart.text.square.fill",
        "figure.mind.and.body",
        "chart.line.uptrend.xyaxis",
        "chart.pie.fill",
        "medal.fill",
        "trophy.fill",
        "star.fill",
        "crown.fill",
        "flag.checkered",
        "figure.boxing",
        "figure.climbing",
        "figure.fall",
        "figure.handball",
        "figure.rolling",
        "figure.surfing",
        "bolt.badge.a.fill",
        "bolt.trianglebadge.exclamationmark.fill",
        "cablecar.fill",
        "chevron.up.square.fill",
        "cylinder.split.1x2.fill",
        "figure.2.arms.open",
        "figure.seated.seatbelt",
        "hand.raised.square.fill",
        "heart.square.fill",
        "lanyardcard.fill",
        "macpro.gen3.fill",
        "oval.fill",
        "oval.portrait.fill",
        "pill.fill",
        "play.square.fill",
        "powerplug.fill",
        "restart.circle.fill",
        "road.lanes.curved.left",
        "squareshape.dotted.squareshape",
        "trapezoid.and.line.horizontal.fill",
        "triangle.fill",
        "wrench.adjustable.fill",
        "arrow.up.and.down.circle.fill",
        "arrow.uturn.up.circle.fill",
        "circle.grid.cross.fill",
        "figure.core.training.circle.fill",
        "figure.open.water.swim",
        "rotate.3d.fill",
        "bandage.fill",
        "bell.and.waves.left.and.right.fill",
        "handbag.fill",
        "headphones.circle.fill",
        "lock.shield.fill",
        "shoe.circle.fill",
        "wave.3.backward.circle.fill",
        "gauge.with.dots.needle.bottom.0percent",
        "gauge.with.dots.needle.bottom.50percent",
        "gauge.with.dots.needle.bottom.100percent",
        "barometer",
        "thermometer",
        "wind",
        "list.bullet.rectangle.fill",
        "list.clipboard.fill",
        "menucard.fill",
        "tablecells.fill",
        "tag.fill",
        "text.page",
        "wifi.router.fill",
        "flag.2.crossed.fill",
        "hourglass",
        "lines.measurement.horizontal",
        "sportscourt",
        "stairs",
        "bed.double.fill",
        "drop.fill",
        "fork.knife",
        "tshirt.fill",
        "wind.snow.circle.fill",
        "person.3.fill",
        "megaphone.fill",
        "plus.bubble.fill",
        "quote.bubble.fill",
        "video.fill"
    ]

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
        .alert("Simulação", isPresented: $showSimulacaoOkAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Plano Pro ativado com sucesso (simulação). Nenhuma cobrança foi realizada.")
        }
        .alert("Cancelar Plano", isPresented: $showCancelarPlanoConfirm) {
            Button("Voltar", role: .cancel) { }
            Button("Confirmar cancelamento", role: .destructive) {
                Task {
                    isCancelingPlan = true
                    defer { isCancelingPlan = false }

                    do {
                        try await session.cancelTrainerProAndExpireTrial()
                        showPlanosModal = false
                        showConfirmacaoPro = false
                        planoSliderValue = 0.0
                    } catch {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    }
                }
            }
        } message: {
            Text("Ao cancelar, seu plano volta para Free e o período de 30 dias ficará expirado. Você não poderá criar ou enviar novos treinos.")
        }
        .sheet(isPresented: $showMeusIconesModal) {
            meusIconesModal()
        }
        .sheet(isPresented: $showPlanosModal) {
            planosModal()
        }
        .task(id: currentUid) {
            await loadUserData()
        }
        .onChange(of: session.shouldPresentPlanModal) { _, should in
            if should {
                session.shouldPresentPlanModal = false
                openPlanos()
            }
        }
    }

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
        if session.userType != .STUDENT {
            path.removeAll()
            path.append(
                .teacherStudentsList(
                    selectedCategory: categoriaAtualProfessor,
                    initialFilter: nil
                )
            )
            return
        }

        guard !path.isEmpty else { return }
        path.removeLast()
    }

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
            try await repository.setStudentUnitName(uid: uid, unitName: trimmed)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func openPlanos() {
        let plan = (session.planTypeRaw ?? "FREE").uppercased()
        planoSliderValue = (plan == "PRO") ? 1.0 : 0.0
        showConfirmacaoPro = false
        isConfirmingPro = false
        isCancelingPlan = false
        showPlanosModal = true
    }

    private var planoStatusTexto: String { isPlanActive ? "Ativo" : "Inativo" }
    private var planoStatusForeground: Color { isPlanActive ? Color.green.opacity(0.9) : Color.red.opacity(0.95) }
    private var planoStatusBackground: Color { isPlanActive ? Color.green.opacity(0.16) : Color.red.opacity(0.18) }

    private var planosInfoTextoProfessor: String {
        let plan = (session.planTypeRaw ?? "FREE").uppercased()
        if plan == "PRO" {
            return "PRO • Ativo"
        }

        guard let start = session.trialStartedAt else {
            return "FREE • Faltam 0 dias"
        }

        let trialSeconds: TimeInterval = 30 * 24 * 60 * 60
        let endDate = start.addingTimeInterval(trialSeconds)
        let remainingSeconds = endDate.timeIntervalSince(Date())

        let days = Int(ceil(remainingSeconds / (24 * 60 * 60)))
        let safeDays = max(0, days)

        return "FREE • Faltam \(safeDays) dias"
    }

    private var planosBadgeFgProfessor: Color {
        let plan = (session.planTypeRaw ?? "FREE").uppercased()
        if plan == "PRO" {
            return Color.green.opacity(0.9)
        }

        let canUse = session.canUseTrainerProFeatures
        return canUse ? Color.green.opacity(0.9) : Color.red.opacity(0.95)
    }

    private var planosBadgeBgProfessor: Color {
        let plan = (session.planTypeRaw ?? "FREE").uppercased()
        if plan == "PRO" {
            return Color.green.opacity(0.16)
        }

        let canUse = session.canUseTrainerProFeatures
        return canUse ? Color.green.opacity(0.16) : Color.red.opacity(0.18)
    }

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

    private func optionsCard() -> some View {
        VStack(spacing: 0) {

            optionRow(icon: "ruler", title: "Trocar unidade", trailing: .chevron) {
                openTrocarUnidade()
            }
            divider()

            if session.userType == .STUDENT {
                optionRow(
                    icon: "crown.fill",
                    title: "Planos",
                    trailing: .coloredBadge(planoStatusTexto, fg: planoStatusForeground, bg: planoStatusBackground)
                )
            } else {
                optionRow(
                    icon: "crown.fill",
                    title: "Planos",
                    trailing: .coloredBadgeWithChevron(planosInfoTextoProfessor, fg: planosBadgeFgProfessor, bg: planosBadgeBgProfessor)
                ) {
                    openPlanos()
                }
            }

            if session.userType == .STUDENT {
                divider()
                optionRow(icon: "envelope.fill", title: "Mensagens", trailing: .chevron) {
                    path.append(.studentMessages(category: categoriaAtualAluno))
                }

                divider()
                optionRow(icon: "text.bubble.fill", title: "Feedbacks", trailing: .chevron) {
                    path.append(.studentFeedbacks(category: categoriaAtualAluno))
                }

                divider()
                optionRow(icon: "square.grid.2x2.fill", title: "Meus Ícones", trailing: .chevron) {
                    showMeusIconesModal = true
                }

            } else {
                divider()
                optionRow(icon: "square.grid.2x2.fill", title: "Meus Ícones", trailing: .chevron) {
                    showMeusIconesModal = true
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
        case coloredBadgeWithChevron(String, fg: Color, bg: Color)
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

            case .coloredBadgeWithChevron(let value, let fg, let bg):
                HStack(spacing: 10) {
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(fg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(bg))

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

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

    private func planosModal() -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            NavigationStack {
                ZStack {
                    Theme.Colors.headerBackground
                        .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 14) {

                        Text("Planos")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))

                        Text("Arraste para simular a mudança de Free para Pro.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.55))

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Free")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.80))

                                Spacer()

                                Text("Pro")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.80))
                            }

                            Slider(value: $planoSliderValue, in: 0...1, step: 0.01)
                                .tint(Color.green.opacity(0.85))
                                .onChange(of: planoSliderValue) { _, newValue in
                                    if newValue >= 0.90 {
                                        showConfirmacaoPro = true
                                    }
                                }

                            Text(planoSliderValue >= 0.90 ? "Selecionado: Pro" : "Selecionado: Free")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .padding(14)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(14)

                        Button {
                            showCancelarPlanoConfirm = true
                        } label: {
                            HStack(spacing: 10) {
                                Text("Cancelar Plano")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.92))

                                Spacer()

                                if isCancelingPlan {
                                    ProgressView()
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isCancelingPlan)

                        Spacer(minLength: 0)
                    }
                    .padding(16)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fechar") {
                            showPlanosModal = false
                        }
                        .foregroundColor(.green)
                    }
                }
                .navigationDestination(isPresented: $showConfirmacaoPro) {
                    confirmacaoProView()
                }
            }
        }
        .onAppear {
            let plan = (session.planTypeRaw ?? "FREE").uppercased()
            planoSliderValue = (plan == "PRO") ? 1.0 : 0.0
        }
    }

    private func confirmacaoProView() -> some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {

                Text("Confirmar Plano Pro")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Text("Valor: R$ 49,90")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green.opacity(0.92))

                Text("Esta é uma simulação. Nenhuma cobrança real será feita neste momento.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.55))

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Button {
                        showConfirmacaoPro = false
                        planoSliderValue = 0.0
                    } label: {
                        Text("Voltar")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isConfirmingPro)

                    Button {
                        Task {
                            isConfirmingPro = true
                            defer { isConfirmingPro = false }

                            do {
                                try await session.upgradeTrainerToProSimulated()
                                showPlanosModal = false
                                showConfirmacaoPro = false
                                showSimulacaoOkAlert = true
                            } catch {
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text("Confirmar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.92))

                            if isConfirmingPro {
                                ProgressView()
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.green.opacity(0.20)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isConfirmingPro)
                }
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fechar") {
                    showPlanosModal = false
                    showConfirmacaoPro = false
                }
                .foregroundColor(.green)
            }
        }
    }

    private func meusIconesModal() -> some View {
        NavigationStack {
            ZStack {
                Theme.Colors.headerBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Toque em um ícone para copiar o nome.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))
                                .padding(.top, 12)

                            let columns: [GridItem] = [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ]

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(treinoIcons, id: \.self) { iconName in
                                    Button {
                                        UIPasteboard.general.string = iconName
                                        copiedIconName = iconName
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                            if copiedIconName == iconName {
                                                copiedIconName = nil
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: iconName)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.green.opacity(0.9))
                                                .frame(width: 28)

                                            Text(iconName)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.92))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.85)

                                            Spacer(minLength: 0)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(Theme.Colors.cardBackground)
                                        .cornerRadius(14)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)

                        Spacer(minLength: 0)
                    }
                }

                if let copied = copiedIconName {
                    VStack {
                        Spacer()
                        Text("Copiado: \(copied)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.35))
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                            .padding(.bottom, 18)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.18), value: copiedIconName)
                }
            }
            .navigationTitle("Meus Ícones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        showMeusIconesModal = false
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}

