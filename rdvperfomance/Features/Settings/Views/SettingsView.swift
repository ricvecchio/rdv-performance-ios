import SwiftUI

// Tela de configurações do aplicativo
struct SettingsView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380

    @State private var preferredWeightUnitRawState: String = WeightUnit.kg.rawValue
    @State private var showWeightUnitSheet: Bool = false

    private let preferredWeightUnitKey: String = "preferredWeightUnit"

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Retorna a unidade de peso preferida
    private var preferredWeightUnit: WeightUnit {
        WeightUnit(rawValue: preferredWeightUnitRawState) ?? .kg
    }

    // Constrói a interface da tela de configurações
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

                        VStack(alignment: .leading, spacing: 16) {

                            sectionTitle("CONTA")
                            accountCard()

                            sectionTitle("PREFERÊNCIAS")
                            preferencesCard()

                            sectionTitle("SUPORTE & LEGAL")
                            supportLegalCard()

                            Color.clear.frame(height: 16)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)

                footerForUser()
                    .frame(height: Theme.Layout.footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .blur(radius: showWeightUnitSheet ? 8 : 0)
        .animation(.easeInOut(duration: 0.20), value: showWeightUnitSheet)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Configurações")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }

        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)

        .onAppear {
            let raw = UserDefaults.standard.string(forKey: preferredWeightUnitKey) ?? WeightUnit.kg.rawValue
            if preferredWeightUnitRawState != raw {
                preferredWeightUnitRawState = raw
            }
        }
        .onChange(of: preferredWeightUnitRawState) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: preferredWeightUnitKey)
        }
        .sheet(isPresented: $showWeightUnitSheet) {
            WeightUnitSheetView(selectedUnitRaw: $preferredWeightUnitRawState)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
                    isPerfilSelected: false
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

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
            .padding(.horizontal, 6)
    }

    private func accountCard() -> some View {
        card {
            cardRow(icon: "person.crop.circle", title: "Editar Perfil") {
                path.append(.editarPerfil)
            }
            divider()
            cardRow(icon: "key.fill", title: "Alterar Senha") {
                path.append(.alterarSenha)
            }
            divider()
            cardRow(icon: "trash.fill", title: "Excluir Conta") {
                path.append(.excluirConta)
            }
        }
    }

    private func preferencesCard() -> some View {
        card {
            cardRow(
                icon: "ruler.fill",
                title: "Unidade de Medida",
                trailingText: preferredWeightUnit.shortLabel
            ) {
                showWeightUnitSheet = true
            }
        }
    }

    private func supportLegalCard() -> some View {
        card {

            cardRow(icon: "info.circle.fill", title: "Sobre") {
                path.append(.sobre)
            }

            divider()

            cardRow(icon: "questionmark.circle.fill", title: "Central de Ajuda") {
                path.append(.infoLegal(.helpCenter))
            }
            divider()
            cardRow(icon: "hand.raised.fill", title: "Políticas de Privacidade") {
                path.append(.infoLegal(.privacyPolicy))
            }
            divider()
            cardRow(icon: "doc.text.fill", title: "Termos de Uso") {
                path.append(.infoLegal(.termsOfUse))
            }
            divider()

            cardRow(icon: "gamecontroller.fill", title: "Preview do Progresso") {
                path.append(.spriteDemo)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
    }

    private func divider() -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 54)
    }

    private func cardRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.green.opacity(0.85))
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func cardRow(icon: String, title: String, trailingText: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.green.opacity(0.85))
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Text(trailingText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private enum WeightUnit: String, CaseIterable {
    case kg
    case lbs

    var title: String {
        switch self {
        case .kg: return "⚖️ kg (quilograma)"
        case .lbs: return "⚖️ lbs (libra)"
        }
    }

    var shortLabel: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
}

private struct WeightUnitSheetView: View {

    @Binding var selectedUnitRaw: String
    @Environment(\.dismiss) private var dismiss

    private var selectedUnit: WeightUnit {
        WeightUnit(rawValue: selectedUnitRaw) ?? .kg
    }

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    Text("Unidade de Medida")
                        .font(Theme.Fonts.headerTitle())
                        .foregroundColor(.white)

                    Spacer()

                    Button("Fechar") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryGreen)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 12) {

                    VStack(spacing: 0) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Button {
                                selectedUnitRaw = unit.rawValue
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(unit.title)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white.opacity(0.92))

                                    Spacer()

                                    if unit == selectedUnit {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.Colors.primaryGreen)
                                            .font(.system(size: 18, weight: .semibold))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.white.opacity(0.25))
                                            .font(.system(size: 18, weight: .regular))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if unit != WeightUnit.allCases.last {
                                Divider()
                                    .background(Theme.Colors.divider)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(14)

                    Text("Essa preferência será usada para exibir cargas e referências de treino.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.horizontal, 6)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
