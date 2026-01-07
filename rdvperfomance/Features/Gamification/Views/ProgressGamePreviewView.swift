import SwiftUI
import SpriteKit

// MARK: - Preview (Settings)
struct ProgressGamePreviewView: View {

    @StateObject private var vm = ProgressGameViewModel(mode: .preview)

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        Text("Preview interativo do progresso gamificado.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Preview SpriteKit
                        SpriteKitPreviewCard(metrics: vm.metrics)

                        Button {
                            Task { await vm.randomizePreview() }
                        } label: {
                            HStack {
                                Image(systemName: "shuffle")
                                Text("Randomizar cenário")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.green.opacity(0.16)))
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
            }
        }
        .task { await vm.load() }
    }
}

private struct SpriteKitPreviewCard: View {

    let metrics: ProgressMetrics

    var body: some View {
        VStack(spacing: 12) {
            SpriteKitPreviewPanel(metrics: metrics)
                .frame(height: 320)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SpriteKitPreviewPanel: View {

    let metrics: ProgressMetrics
    @State private var scene = ProgressGameSceneFactory.makeScene(size: CGSize(width: 380, height: 320))

    var body: some View {
        SpriteView(scene: scene)
            .onAppear { scene.update(with: metrics, animated: false) }
            .onChange(of: metrics) { _, newValue in
                scene.update(with: newValue, animated: true)
            }
    }
}

