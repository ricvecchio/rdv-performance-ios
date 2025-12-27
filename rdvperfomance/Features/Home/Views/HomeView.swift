import SwiftUI

struct HomeView: View {

    @Binding var path: [AppRoute]

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                HeaderBar {
                    headerView()
                }

                GeometryReader { proxy in
                    let tileHeight = proxy.size.height / 3

                    VStack(spacing: 0) {

                        programaTile(
                            title: "Crossfit",
                            imageName: "rdv_programa_crossfit_horizontal",
                            height: tileHeight,
                            imageTitle: "Crossfit",
                            tipo: .crossfit
                        )

                        programaTile(
                            title: "Academia",
                            imageName: "rdv_programa_academia_horizontal",
                            height: tileHeight,
                            imageTitle: "Academia",
                            tipo: .academia
                        )

                        programaTile(
                            title: "Treinos em casa",
                            imageName: "rdv_programa_treinos_em_casa_horizontal",
                            height: tileHeight,
                            imageTitle: "Treinos em casa",
                            tipo: .emCasa
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }

                FooterBar(
                    path: $path,
                    kind: .homeSobrePerfil(
                        isHomeSelected: true,
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
        .toolbar(.hidden, for: .navigationBar)
    }

    private func programaTile(
        title: String,
        imageName: String,
        height: CGFloat,
        imageTitle: String,
        tipo: TreinoTipo
    ) -> some View {

        Button {
            ultimoTreinoSelecionado = tipo.rawValue
            path.append(.treinos(tipo))
        } label: {

            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width

                    // Base (imagem)
                    ZStack {
                        Color.black

                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: w - 16)
                            .frame(maxHeight: .infinity)
                            .overlay(
                                Rectangle()
                                    .fill(Color.black.opacity(0.7))
                                    .mask(
                                        HStack(spacing: 0) {
                                            LinearGradient(
                                                gradient: Gradient(colors: [.black, .clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .frame(width: 20)

                                            Spacer()

                                            LinearGradient(
                                                gradient: Gradient(colors: [.black, .clear]),
                                                startPoint: .trailing,
                                                endPoint: .leading
                                            )
                                            .frame(width: 20)
                                        }
                                    )
                            )
                    }
                    .frame(width: w, height: height)
                    .clipped()

                    // ✅ 1) PRIMEIRO aplica o gradiente (por trás dos textos)
                    .overlay {
                        LinearGradient(
                            colors: [
                                .black.opacity(0.70),
                                .black.opacity(0.15),
                                .clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    }

                    // ✅ 2) DEPOIS desenha os textos (sempre sólidos, sem “lavar”)
                    .overlay(alignment: .bottomLeading) {
                        ZStack(alignment: .bottomLeading) {

                            // Texto grande
                            Text(imageTitle)
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 3)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .padding(.leading, 200)
                                .padding(.trailing, 24)
                                .padding(.bottom, 40)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Texto pequeno (Crossfit / Academia / Treinos em casa)
                            Text(title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .padding(.leading, 24)
                                .padding(.trailing, 24)
                                .padding(.bottom, 12)
                        }
                    }
                }
                .frame(height: height)

                // Gradientes finos top/bottom
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
        .buttonStyle(.plain)
        .background(
            Color.black.opacity(0.3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .frame(height: height)
    }

    private func headerView() -> some View {
        ZStack {
            Text("Home")
                .font(Theme.Fonts.headerTitle())
                .foregroundColor(.white)

            HStack {
                Button {
                    if !path.isEmpty { path.removeLast() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.leading, 16)
                        .contentShape(Rectangle())
                }

                Spacer()
            }
        }
    }
}

