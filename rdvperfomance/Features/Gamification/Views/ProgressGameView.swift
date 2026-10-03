import SwiftUI
import SpriteKit
import Foundation

/// Tela reutilizável para exibição de progresso gamificado para aluno ou professor
struct ProgressGameView: View {
    @Environment(\.locale) private var locale

    /// Path de navegação para controle de stack
    @Binding var path: [AppRoute]
    /// Modo de operação que define fonte de dados
    let mode: ProgressGameMode

    /// ViewModel que gerencia estado e dados da tela
    @StateObject private var vm: ProgressGameViewModel

    /// Inicializa a view com path de navegação e modo específico
    init(path: Binding<[AppRoute]>, mode: ProgressGameMode) {
        self._path = path
        self.mode = mode
        _vm = StateObject(wrappedValue: ProgressGameViewModel(mode: mode))
    }

    var body: some View {
        ZStack {
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 12) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                content
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer(minLength: 0)
            }
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
                Text("gamification.progress.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await vm.load() }
    }

    /// View de conteúdo principal com painel SpriteKit e card fallback
    private var content: some View {
        VStack(spacing: 12) {

            if vm.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 20)
            }

            /// Painel SpriteKit com clipping para evitar overflow visual
            SpriteKitPanel(metrics: vm.metrics, locale: locale)
                .frame(height: 340)
                .padding(.horizontal, 2)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

            fallbackCard
        }
    }

    /// Card de fallback com informações textuais das métricas
    private var fallbackCard: some View {
        let percent = Int((vm.metrics.weeklyCompletion * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            Text(vm.metrics.displayName ?? String(localized: "gamification.progress.student_title", locale: locale))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text(progressSummary(percent: percent, streakDays: vm.metrics.streakDays))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))

            if !vm.metrics.badges.isEmpty {
                let format = String(localized: "gamification.badges.summary", locale: locale)
                Text(
                    String(
                        format: format,
                        locale: locale,
                        arguments: [localizedBadgeList]
                    )
                )
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            } else {
                Text("gamification.badges.empty_summary")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func progressSummary(percent: Int, streakDays: Int) -> String {
        let format = String(
            localized: streakDays == 1
                ? "gamification.progress.summary.one_day"
                : "gamification.progress.summary.other_days",
            locale: locale
        )
        return String(
            format: format,
            locale: locale,
            arguments: [Int64(percent), Int64(streakDays)]
        )
    }

    private var localizedBadgeList: String {
        let titles = vm.metrics.badges.map { $0.localizedTitle(locale: locale) }
        let formatter = ListFormatter()
        formatter.locale = locale
        return formatter.string(from: titles) ?? titles.joined(separator: ", ")
    }

    /// Remove última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

/// Container SpriteKit que atualiza cena conforme métricas mudam
private struct SpriteKitPanel: View {

    let metrics: ProgressMetrics
    let locale: Locale

    /// Cena criada uma única vez e redimensionada pelo container real
    @State private var scene: ProgressGameScene = ProgressGameSceneFactory.makeScene(
        size: CGSize(width: 10, height: 10)
    )

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene)
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
                .onChange(of: locale) { _, newLocale in
                    scene.update(with: metrics, locale: newLocale, animated: false)
                }
        }
        .clipped()
    }

    /// Atualiza tamanho da cena apenas se diferente do atual evitando trabalho desnecessário
    private func applySizeIfNeeded(_ size: CGSize) {
        guard size.width > 10, size.height > 10 else { return }

        if scene.size != size {
            scene.size = size
        }
    }
}
