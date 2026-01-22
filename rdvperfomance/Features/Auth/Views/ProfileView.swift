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

    private let treinoIcons = [
        // Básicos que você já usa
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

        // Cross training / funcional
        "figure.cross.training",
        "figure.cross.training.circle",
        "figure.flexibility",
        "figure.gymnastics",
        "figure.highintensity.intervaltraining",
        "figure.mixed.cardio",
        "figure.yoga",
        "figure.pilates",

        // Musculação / força
        "figure.strengthtraining.functional",
        "figure.strengthtraining.functional.circle",
        "figure.cooldown",
        "figure.core.training",
        "figure.arms.open",
        "figure.stand",
        "figure.squat",
        "figure.lunge",

        // Cardio / condicionamento
        "figure.rower",
        "figure.stair.stepper",
        "figure.outdoor.cycle",
        "figure.indoor.cycle",
        "figure.jumprope",
        "figure.hiking",

        // Equipamentos / treino simbólicos
        "dumbbell.fill",
        "backpack.fill",          // bolsa de treino / gym bag
        "waterbottle.fill",       // hidratação
        "timer",
        "speedometer",
        "target",
        "scope",
        "line.diagonal.arrow",
        "arrow.triangle.2.circlepath",

        // Saúde / corpo / performance
        "lungs.fill",
        "waveform.path.ecg",
        "heart.text.square.fill",
        "figure.mind.and.body",

        // Performance / progresso
        "chart.line.uptrend.xyaxis",
        "chart.pie.fill",
        "medal.fill",
        "trophy.fill",
        "star.fill",
        "crown.fill",
        "flag.checkered",
        
        // === NOVOS ÍCONES ADICIONADOS ===
        
        // **EQUIPAMENTOS DE CROSSFIT**
        "figure.boxing",               // Saco de pancada / boxe
        "figure.climbing",             // Corda de escalada
        "figure.fall",                 // Caixa de salto (drop)
        "figure.handball",             // Bola medicinal / wall ball
        "figure.rolling",              // Pneu de arrasto
        "figure.surfing",              // Remo ergômetro / ski erg
        
        // **EQUIPAMENTOS DE ACADEMIA**
        "bolt.badge.a.fill",           // Máquinas elétricas
        "bolt.trianglebadge.exclamationmark.fill", // Power rack
        "cablecar.fill",               // Máquina de cabo
        "chevron.up.square.fill",      // Leg press / hack squat
        "cylinder.split.1x2.fill",     // Anilhas / discos
        "figure.2.arms.open",          // Peck deck / crucifixo
        "figure.seated.seatbelt",      // Máquina sentada
        "hand.raised.square.fill",     // Luvas de treino
        "heart.square.fill",           // Monitor cardíaco
        "lanyardcard.fill",            // Acessórios de segurança
        "macpro.gen3.fill",            // Rack de pesos (metáfora)
        "oval.fill",                   // Kettlebell
        "oval.portrait.fill",          // Bola suíça / physioball
        "pill.fill",                   // Suplementos
        "play.square.fill",            // Início de circuito
        "powerplug.fill",              // Energia / potência
        "restart.circle.fill",         // Recomeçar / circuito
        "road.lanes.curved.left",      // Trilha de corrida / pista
        "squareshape.dotted.squareshape", // Grade / jaula
        "trapezoid.and.line.horizontal.fill", // Banco de exercícios
        "triangle.fill",               // Pirâmide / carga progressiva
        "wrench.adjustable.fill",      // Ajustes de equipamento
        
        // **MOVIMENTOS ESPECÍFICOS**
        "arrow.up.and.down.circle.fill",     // Thrusters / clean & jerk
        "arrow.uturn.up.circle.fill",        // Burpees / movimentos complexos
        "circle.grid.cross.fill",            // Snatch / arranco
        "figure.core.training.circle.fill",  // Core training
        "figure.open.water.swim",            // Nado seco / butterfly
        "rotate.3d.fill",                    // Rotação / torção
        
        // **ACESSÓRIOS E SEGURANÇA**
        "bandage.fill",                      // Faixas / wraps
        "bell.and.waves.left.and.right.fill",// Sinal sonoro / timer
        "handbag.fill",                      // Bolsa de equipamentos
        "headphones.circle.fill",            // Fones de ouvido
        "lock.shield.fill",                  // Cadeado / segurança
        "shoe.circle.fill",                  // Tênis de treino
        "wave.3.backward.circle.fill",       // Respiração / wind
        
        // **MEDIÇÃO E CONTROLE**
        "gauge.with.dots.needle.bottom.0percent",  // Medidor de esforço
        "gauge.with.dots.needle.bottom.50percent",
        "gauge.with.dots.needle.bottom.100percent",
        "barometer",                         // Pressão / intensidade
        "thermometer",                       // Temperatura corporal
        "wind",                              // Ventilação / fôlego
        
        // **ESTRUTURA E ORGANIZAÇÃO**
        "list.bullet.rectangle.fill",        // Planilha de treino
        "list.clipboard.fill",               // Clipboard de treino
        "menucard.fill",                     // Cardápio de exercícios
        "tablecells.fill",                   // Grade de exercícios
        "tag.fill",                          // Etiqueta de exercício
        "text.page",                         // Descrição técnica
        "wifi.router.fill",                  // Conexão / app conectado
        
        // **COMPETIÇÃO E DESAFIO**
        "flag.2.crossed.fill",               // Competição
        "hourglass",                         // Contagem regressiva
        "lines.measurement.horizontal",      // Marcação de recorde
        "sportscourt",                       // Box de CrossFit
        "stairs",                            // Escada / step-up
        
        // **RECUPERAÇÃO**
        "bed.double.fill",                   // Descanso
        "drop.fill",                         // Hidratação extra
        "fork.knife",                        // Nutrição pós-treino
        "tshirt.fill",                      // Roupa de treino
        "wind.snow.circle.fill",            // Geladeira / água fria
        
        // **COMUNIDADE E SOCIAL**
        "person.3.fill",                    // Grupo / classe
        "megaphone.fill",                   // Coach instruindo
        "plus.bubble.fill",                 // Feedback positivo
        "quote.bubble.fill",                // Dicas técnicas
        "video.fill"                        // Demonstração em vídeo
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
        .sheet(isPresented: $showMeusIconesModal) {
            meusIconesModal()
        }
        .task(id: currentUid) {
            await loadUserData()
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

    private var planoStatusTexto: String { isPlanActive ? "Ativo" : "Inativo" }
    private var planoStatusForeground: Color { isPlanActive ? Color.green.opacity(0.9) : Color.red.opacity(0.95) }
    private var planoStatusBackground: Color { isPlanActive ? Color.green.opacity(0.16) : Color.red.opacity(0.18) }

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

                // ✅ Agora fica abaixo de Feedbacks
                divider()
                optionRow(icon: "square.grid.2x2.fill", title: "Meus Ícones", trailing: .chevron) {
                    showMeusIconesModal = true
                }

            } else {
                // Para professor (sem Feedbacks), mantém no card após Planos
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

