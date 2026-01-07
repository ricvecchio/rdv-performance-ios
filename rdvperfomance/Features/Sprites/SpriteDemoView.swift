import SwiftUI
import SpriteKit

struct SpriteDemoView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    private let contentMaxWidth: CGFloat = 380
    private let cornerRadius: CGFloat = 14

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

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
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {

                            Text("Visualize um preview interativo de evolução/consistência.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            previewCard()

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
                Text("Preview do Progresso")
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
                    isPerfilSelected: false
                )
            )
        }
    }

    /// ✅ Ajuste final: maximiza largura útil do SpriteKit dentro do card
    private func previewCard() -> some View {
        VStack(spacing: 0) {

            // Top padding pequeno só pra “respirar”
            Color.clear.frame(height: 8)

            SpriteKitPreviewPanel(metrics: vm.metrics)
                .frame(height: 420) // <- era 340
                .frame(maxWidth: .infinity)
                .clipped()
                .padding(.horizontal, 2) // <- era 10 (quase full width)

            Color.clear.frame(height: 8)
        }
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

// MARK: - Panel com sizing real (evita vazamento lateral)
private struct SpriteKitPreviewPanel: View {

    let metrics: ProgressMetrics

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
        guard size.width > 10, size.height > 10 else { return }
        if scene.size != size {
            scene.size = size
        }
    }
}

