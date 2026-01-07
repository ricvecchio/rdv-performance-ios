import SwiftUI
import SpriteKit

// MARK: - Tela reutilizável (Aluno / Professor)
struct ProgressGameView: View {

    @Binding var path: [AppRoute]
    let mode: ProgressGameMode

    @StateObject private var vm: ProgressGameViewModel

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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Progresso")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await vm.load() }
    }

    private var content: some View {
        VStack(spacing: 12) {

            if vm.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 20)
            }

            // ✅ Painel SpriteKit maior e com clipping consistente
            SpriteKitPanel(metrics: vm.metrics)
                .frame(height: 340) // <- era 320 (expandiu um pouco)
                .padding(.horizontal, 2) // micro-ajuste para “acompanhar” o card de baixo visualmente
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

    private var fallbackCard: some View {
        let percent = Int((vm.metrics.weeklyCompletion * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            Text(vm.metrics.displayName ?? "Progresso do aluno")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Conclusão: \(percent)% • Streak: \(vm.metrics.streakDays) dias")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))

            if !vm.metrics.badges.isEmpty {
                Text("Badges: \(vm.metrics.badges.map(\.title).joined(separator: ", "))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            } else {
                Text("Badges: —")
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

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

// MARK: - SpriteKit container com atualização segura
private struct SpriteKitPanel: View {

    let metrics: ProgressMetrics

    // ✅ cena criada uma única vez; tamanho ajustado pelo container real (GeometryReader)
    @State private var scene: ProgressGameScene = ProgressGameSceneFactory.makeScene(
        size: CGSize(width: 10, height: 10)
    )

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene)
                .onAppear {
                    applySizeIfNeeded(geo.size)
                    scene.update(with: metrics, animated: false)
                }
                .onChange(of: geo.size) { _, newSize in
                    applySizeIfNeeded(newSize)
                }
                .onChange(of: metrics) { _, newValue in
                    scene.update(with: newValue, animated: true)
                }
        }
        .clipped()
    }

    private func applySizeIfNeeded(_ size: CGSize) {
        // Evita ajustes com tamanho inválido durante layout
        guard size.width > 10, size.height > 10 else { return }

        // Só atualiza se mudou de fato (evita trabalho desnecessário)
        if scene.size != size {
            scene.size = size
        }
    }
}

