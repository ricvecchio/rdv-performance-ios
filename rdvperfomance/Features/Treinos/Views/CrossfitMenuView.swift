// CrossfitMenuView.swift — Menu com opções específicas de Crossfit (WOD, Benchmark, etc.)
import SwiftUI

struct CrossfitMenuView: View {

    @Binding var path: [AppRoute]

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

                GeometryReader { proxy in
                    let tileHeight = proxy.size.height / 5

                    VStack(spacing: 0) {

                        menuTile(
                            title: "WOD",
                            imageName: "rdv_crossfit_wod_horizontal",
                            height: tileHeight
                        )

                        menuTile(
                            title: "BENCHMARK",
                            imageName: "rdv_crossfit_benchmark_horizontal",
                            height: tileHeight
                        )

                        menuTile(
                            title: "MEUS RECORDES",
                            imageName: "rdv_crossfit_meusrecordes_horizontal",
                            height: tileHeight
                        )

                        menuTile(
                            title: "PROGRESSOS",
                            imageName: "rdv_crossfit_progressos_horizontal",
                            height: tileHeight
                        )

                        menuTile(
                            title: "MONTE SEU TREINO",
                            imageName: "rdv_crossfit_monteseutreino_horizontal",
                            height: tileHeight
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }

                FooterBar(
                    path: $path,
                    kind: .treinosComPerfil(
                        treinoTitle: TreinoTipo.crossfit.titulo,
                        treinoIcon: AnyView(TreinoTipo.crossfit.iconeRodapeTreinos),
                        isHomeSelected: false,
                        isTreinoSelected: true,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            // ✅ Perfil no canto direito: apenas foto redonda (SEM Button para não criar estilo/bolha)
            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_user_default", size: 38)
                    .onTapGesture {
                        // opcional: navegar para perfil
                    }
                    .background(Color.clear)
            }
        })
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Tile que inicia navegação para seção de treinos
    private func menuTile(
        title: String,
        imageName: String,
        height: CGFloat
    ) -> some View {

        Button {
            path.append(.treinos(.crossfit))
        } label: {
            menuTileLayout(
                title: title,
                imageName: imageName,
                height: height
            )
        }
        .buttonStyle(.plain)
        .background(
            Color.black.opacity(0.3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .frame(height: height)
    }

    // Layout visual do tile com imagem e título
    private func menuTileLayout(
        title: String,
        imageName: String,
        height: CGFloat
    ) -> some View {

        ZStack {
            GeometryReader { geo in
                let w = geo.size.width

                ZStack {

                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: height)
                        .clipped()
                        .blur(radius: 10)
                        .opacity(0.55)

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: w, height: height)

                    Rectangle()
                        .fill(Color.black.opacity(0.45))

                    LinearGradient(
                        colors: [
                            .black.opacity(0.70),
                            .black.opacity(0.20),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )

                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.75), radius: 4, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(width: w, height: height)
                .contentShape(Rectangle())
            }
            .frame(height: height)

            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 4)

                Spacer()

                LinearGradient(
                    colors: [.black.opacity(0.15), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 4)
            }
            .frame(height: height)
            .allowsHitTesting(false)
        }
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
