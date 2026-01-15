import SwiftUI

// Tela inicial do ALUNO (o professor não deve mais cair aqui; AppRouter já redireciona)
struct HomeView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    // ✅ Persistência do último treino selecionado (sem UserDefaults manual)
    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private let contentMaxWidth: CGFloat = 380

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

                footerAluno
                    .frame(height: Theme.Layout.footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // Footer do aluno (mantém padrão atual)
    private var footerAluno: some View {
        FooterBar(
            path: $path,
            kind: .agendaSobrePerfil(
                isAgendaSelected: false,
                isSobreSelected: false,
                isPerfilSelected: false
            )
        )
    }

    // Cria um tile clicável para cada programa de treino (fluxo do aluno)
    private func programaTile(
        title: String,
        imageName: String,
        height: CGFloat,
        imageTitle: String,
        tipo: TreinoTipo
    ) -> some View {

        Button {
            // ✅ Persistimos para manter consistência com outras telas
            ultimoTreinoSelecionado = tipo.rawValue

            // ✅ HomeView agora é somente do aluno
            guard let uid = session.uid else { return }
            let name = session.userName ?? "Aluno"
            path.append(.studentAgenda(studentId: uid, studentName: name))
        } label: {
            tileLayout(
                title: title,
                imageName: imageName,
                height: height,
                imageTitle: imageTitle
            )
        }
        .buttonStyle(.plain)
        .background(
            Color.black.opacity(0.3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .frame(height: height)
    }

    // Layout visual do tile com imagem de fundo e textos (mantido como estava)
    private func tileLayout(
        title: String,
        imageName: String,
        height: CGFloat,
        imageTitle: String
    ) -> some View {

        ZStack {
            ZStack {
                Color.black

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: height)
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
                                    .frame(width: 28)

                                    Spacer()

                                    LinearGradient(
                                        gradient: Gradient(colors: [.black, .clear]),
                                        startPoint: .trailing,
                                        endPoint: .leading
                                    )
                                    .frame(width: 28)
                                }
                            )
                    )
            }
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)

            LinearGradient(
                colors: [.black.opacity(0.70), .black.opacity(0.15), .clear],
                startPoint: .bottom,
                endPoint: .top
            )

            VStack {
                Spacer()
                ZStack(alignment: .bottomLeading) {
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
            .frame(maxWidth: .infinity, maxHeight: height)

            VStack {
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 4)
                Spacer()
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: 4)
            }
            .frame(height: height)
            .allowsHitTesting(false)
        }
        .frame(height: height)
        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        .clipped()
    }
}

