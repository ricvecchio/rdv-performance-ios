import SwiftUI

// MARK: - HOME PAGE (antiga ProgramaPage)
struct HomePage: View {

    @Binding var path: [AppRoute]

    private let headerHeight: CGFloat = 52
    private let footerHeight: CGFloat = 70

    // ✅ guarda o último treino escolhido (para o botão "Treinos" do meio)
    @AppStorage("ultimoTreinoSelecionado") private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                headerView()
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.70))

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
                            title: "Séries em casa",
                            imageName: "rdv_programa_series_em_casa_horizontal",
                            height: tileHeight,
                            imageTitle: "Séries em casa",
                            tipo: .emCasa
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }

                footerView()
                    .frame(height: footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.75))
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - TILE
    private func programaTile(
        title: String,
        imageName: String,
        height: CGFloat,
        imageTitle: String,
        tipo: TreinoTipo
    ) -> some View {

        Button {
            // ✅ salva o último treino e navega para Treinos
            ultimoTreinoSelecionado = tipo.rawValue
            path.append(.treinos(tipo))
        } label: {

            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width

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
                    .overlay(alignment: .bottomLeading) {
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
                    }
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
                    .overlay(alignment: .bottomLeading) {
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
        .buttonStyle(.plain)
        .background(
            Color.black.opacity(0.3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .frame(height: height)
    }

    // MARK: - HEADER
    private func headerView() -> some View {
        ZStack {
            Text("Home")
                .font(.system(size: 17, weight: .semibold))
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

    // MARK: - FOOTER (Home | Treinos | Sobre)
    private func footerView() -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 28) {

                // ✅ Home selecionado
                Button {
                    goHome()
                } label: {
                    footerItem(icon: "house", title: "Home", isSelected: true)
                }
                .buttonStyle(.plain)

                // ✅ Treinos (meio)
                Button {
                    let tipo = TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
                    path.append(.treinos(tipo))
                } label: {
                    footerItem(icon: "dumbbell", title: "Treinos", isSelected: false)
                }
                .buttonStyle(.plain)

                // ✅ Sobre
                Button {
                    path.append(.sobre)
                } label: {
                    footerItem(icon: "bubble.left", title: "Sobre", isSelected: false)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
        }
    }

    private func goHome() {
        // ✅ garante que volta pra Home (e não para Login)
        path.removeAll()
        path.append(.home)
    }

    private func footerItem(icon: String, title: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20))
            Text(title).font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(isSelected ? .green : .white.opacity(0.7))
        .frame(width: 88)
    }
}

