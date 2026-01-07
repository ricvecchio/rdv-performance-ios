import SwiftUI

struct HomeView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

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

                if session.userType == .TRAINER {
                    HStack {
                        Spacer(minLength: 0)
                        teacherAreaCard
                            .frame(maxWidth: contentMaxWidth)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // ✅ Um GeometryReader apenas no container para dividir alturas
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

                footerForCurrentUser()
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
    }

    private var teacherAreaCard: some View {
        Button {
            let categoria = TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
            path.append(.teacherDashboard(category: categoria))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.green.opacity(0.85))
                    .font(.system(size: 16))
                    .frame(width: 26)

                Text("Área do Professor")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func footerForCurrentUser() -> some View {
        if session.userType == .STUDENT {
            FooterBar(
                path: $path,
                kind: .agendaSobrePerfil(
                    isAgendaSelected: false,
                    isSobreSelected: false,
                    isPerfilSelected: false
                )
            )
            .environmentObject(session)
        } else {
            FooterBar(
                path: $path,
                kind: .homeSobrePerfil(
                    isHomeSelected: true,
                    isSobreSelected: false,
                    isPerfilSelected: false
                )
            )
            .environmentObject(session)
        }
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

            if session.userType == .TRAINER {
                path.append(.teacherStudentsList(selectedCategory: tipo, initialFilter: tipo))
            } else {
                guard let uid = session.uid else { return }
                let name = session.userName ?? "Aluno"
                path.append(.studentAgenda(studentId: uid, studentName: name))
            }
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

    // ✅ CORREÇÃO: remover GeometryReader do tile (evita loop de preferences/layout)
    private func tileLayout(
        title: String,
        imageName: String,
        height: CGFloat,
        imageTitle: String
    ) -> some View {

        ZStack {
            // Fundo + imagem ocupando toda largura disponível
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

            // Gradientes finos topo/baixo
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

