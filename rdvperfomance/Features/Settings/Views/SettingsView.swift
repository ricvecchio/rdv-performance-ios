// SettingsView.swift — Tela de configurações com cartões para conta, preferências e legal
import SwiftUI

struct SettingsView: View {

    // Binding de rotas
    @Binding var path: [AppRoute]

    // Largura máxima do conteúdo
    private let contentMaxWidth: CGFloat = 380

    // Preferência persistida para unidade de peso
    @AppStorage("preferredWeightUnit") private var preferredWeightUnitRaw: String = WeightUnit.kg.rawValue

    // Controle do sheet de unidade
    @State private var showWeightUnitSheet: Bool = false

    // Conveniência para o enum seguro
    private var preferredWeightUnit: WeightUnit {
        WeightUnit(rawValue: preferredWeightUnitRaw) ?? .kg
    }

    // Corpo principal com seções e footer
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

                FooterBar(
                    path: $path,
                    kind: .homeSobrePerfil(
                        isHomeSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
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
            }

            ToolbarItem(placement: .principal) {
                Text("Configurações")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)

        // Modal para seleção de unidade de peso
        .sheet(isPresented: $showWeightUnitSheet) {
            WeightUnitSheetView(
                selectedUnitRaw: $preferredWeightUnitRaw
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // Navegação: voltar
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Título de seção
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
            .padding(.horizontal, 6)
    }

    // Cartões: conta, preferências e suporte/legal
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

            // Demo entries (discretos) — não alteram fluxo principal
            divider()
            cardRow(icon: "gamecontroller.fill", title: "SpriteKit (demo)") {
                path.append(.spriteDemo)
            }
            divider()
            cardRow(icon: "arkit", title: "AR (demo)") {
                path.append(.arDemo)
            }
        }
    }

    // Componentes base de layout
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
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

    // Linha simples do card
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

    // Variante com texto à direita
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

// Enum de unidade de peso e utilitários
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

// Sheet para selecionar unidade de peso
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
    }
}
