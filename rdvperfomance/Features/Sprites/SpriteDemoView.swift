import SwiftUI
import SpriteKit

// Tela de demonstração do preview de progresso com SpriteKit
struct SpriteDemoView: View {

    @Binding var path: [AppRoute]
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da PersonalRecordsView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        static let darkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255) // #294A2F (contorno do card "Acesso rápido" da TeacherDashboardView)
    }

    init(
        path: Binding<[AppRoute]>,
        onSelectSection: @escaping (StudentMainSection) -> Void = { _ in }
    ) {
        _path = path
        _ = onSelectSection
    }

    private let contentMaxWidth: CGFloat = 380
    private let cornerRadius: CGFloat = 14

    @StateObject private var vm = ProgressGameViewModel(mode: .preview)

    // Constrói a interface da tela de demonstração
    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            Text("sprites.preview.description")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.Colors.ink(0.55))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            previewCard()

                            Button {
                                Task { await vm.randomizePreview() }
                            } label: {
                                if appTheme == .light {
                                    // Tema Claro: mesmo padrão de cores do botão Sair da ProfileView, com as dimensões do `primaryGreenActionButton()`
                                    HStack(spacing: 10) {
                                        Image(systemName: "shuffle")
                                            .foregroundStyle(Color.white)
                                        Text("gamification.preview.randomize")
                                    }
                                    .padding(.horizontal, 14)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.white)
                                    .padding(.vertical, 14)
                                    .background(AppThemePalette.lightBar.opacity(0.80))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(LightColors.darkGreenBorder, lineWidth: 1)
                                    )
                                } else {
                                    HStack(spacing: 10) {
                                        Image(systemName: "shuffle")
                                            .appThemeIconForeground()
                                        Text("gamification.preview.randomize")
                                    }
                                    .padding(.horizontal, 14)
                                    .primaryGreenActionButton()
                                }
                            }
                            .buttonStyle(.plain)

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
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("sprites.preview.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
        .task { await vm.load() }
    }

    // Retorna card com preview da cena SpriteKit
    private func previewCard() -> some View {
        VStack(spacing: 0) {

            Color.clear.frame(height: 12)

            ZStack {
                Theme.Colors.ink(0.06)

                SpriteKitPreviewPanel(metrics: vm.metrics)
            }
            .frame(height: 480)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppThemeColor(dark: Theme.Colors.ink(0.08).dark, light: LightColors.darkGreenBorder), lineWidth: 1)
            )
            .padding(.horizontal, 12)

            Color.clear.frame(height: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.darkGreenBorder), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// Panel que gerencia o tamanho da cena SpriteKit
private struct SpriteKitPreviewPanel: View {

    let metrics: ProgressMetrics
    @Environment(\.locale) private var locale

    @State private var scene = Self.makePreviewScene()

    // Constrói a view do SpriteKit com gerenciamento de tamanho
    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene, options: [.allowsTransparency])
                .onAppear {
                    applySizeIfNeeded(geo.size)
                    scene.update(with: metrics, locale: locale, animated: false)
                }
                .onChange(of: geo.size) { _, newSize in
                    applySizeIfNeeded(newSize)
                }
                .onChange(of: metrics) { _, newValue in
                    scene.update(with: newValue, locale: locale, animated: true)
                }
                .onChange(of: locale.identifier) { _, _ in
                    scene.update(with: metrics, locale: locale, animated: false)
                }
        }
        .clipped()
    }

    // Aplica o tamanho à cena se necessário
    private func applySizeIfNeeded(_ size: CGSize) {
        guard size.width > 10, size.height > 10 else { return }
        if scene.size != size {
            scene.size = size
        }
    }

    private static func makePreviewScene() -> ProgressGameScene {
        let scene = ProgressGameSceneFactory.makeScene(size: CGSize(width: 10, height: 10))
        scene.configurePreviewBadgeLayout()
        return scene
    }
}
