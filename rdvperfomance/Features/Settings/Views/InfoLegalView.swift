// InfoLegalView.swift — Tela reutilizável para Central de Ajuda, Privacidade e Termos
import SwiftUI

// Modelo simples para seções de conteúdo legal
struct InfoLegalSection: Hashable {
    let title: String?
    let introText: String?
    let bullets: [String]?
}

// View reutilizável que exibe diferentes conteúdos legais com base em `InfoLegalKind`
struct InfoLegalView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    let kind: InfoLegalKind

    private let contentMaxWidth: CGFloat = 380

    // Última categoria para adaptar o footer quando necessário
    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Corpo com conteúdo e footer
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

                        VStack(alignment: .leading, spacing: 16) {

                            contentCard()

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
            }

            ToolbarItem(placement: .principal) {
                Text(kind.screenTitle)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            // Avatar padrão do cabeçalho
            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Footer que varia conforme o tipo de usuário
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

    // Navegação: voltar
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Card que monta o conteúdo das seções do `InfoLegalKind`
    private func contentCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {

            ForEach(kind.sections, id: \.self) { section in

                if let title = section.title {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }

                if let intro = section.introText {
                    Text(intro)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let bullets = section.bullets {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(bullets, id: \.self) { b in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.78))
                                Text(b)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.78))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                Divider()
                    .background(Theme.Colors.divider)
                    .opacity(0.60)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }
}

// Mapeamentos de título e conteúdo para cada InfoLegalKind
private extension InfoLegalKind {

    var screenTitle: String {
        switch self {
        case .helpCenter: return "Central de Ajuda"
        case .privacyPolicy: return "Políticas de Privacidade"
        case .termsOfUse: return "Termos de Uso"
        }
    }

    var bodyTitle: String {
        switch self {
        case .helpCenter: return "Central de Ajuda"
        case .privacyPolicy: return "Política de Privacidade"
        case .termsOfUse: return "Termos de Uso"
        }
    }

    var sections: [InfoLegalSection] {
        switch self {

        case .helpCenter:
            return [
                .init(
                    title: nil,
                    introText: """
Bem-vindo à Central de Ajuda.
Este aplicativo foi desenvolvido para facilitar o acompanhamento de treinos físicos entre alunos e treinadores, de forma simples e organizada. Aqui você encontra orientações básicas sobre o uso do app.
""",
                    bullets: nil
                ),
                .init(title: "👤 Para Alunos", introText: nil, bullets: [
                    "Visualize os treinos enviados pelo seu treinador.",
                    "Marque a conclusão dos exercícios realizados.",
                    "Acompanhe sua evolução ao longo do tempo.",
                    "Registre seu progresso de forma prática."
                ]),
                .init(title: "🏋️‍♂️ Para Treinadores", introText: nil, bullets: [
                    "Cadastre e envie treinos personalizados para seus alunos.",
                    "Acompanhe a evolução e o progresso de cada aluno.",
                    "Utilize o aplicativo como apoio no acompanhamento físico."
                ]),
                .init(
                    title: "❓ Dúvidas Frequentes",
                    introText: """
Caso tenha dificuldades para acessar suas informações ou utilizar alguma funcionalidade, verifique se:
""",
                    bullets: [
                        "Você está conectado à sua conta corretamente.",
                        "Possui conexão com a internet.",
                        "Está utilizando a versão mais recente do aplicativo."
                    ]
                ),
                .init(
                    title: "📬 Suporte",
                    introText: """
Se ainda precisar de ajuda, entre em contato pelo e-mail:
suporte@rdvperfomance.com
""",
                    bullets: nil
                )
            ]

        case .privacyPolicy:
            return [
                .init(
                    title: nil,
                    introText: """
Sua privacidade é importante para nós.
Este aplicativo tem como objetivo auxiliar no acompanhamento de treinos físicos entre alunos e treinadores, respeitando a segurança e a confidencialidade das informações.
""",
                    bullets: nil
                ),
                .init(
                    title: "🔒 Coleta de Informações",
                    introText: "Podemos coletar informações básicas fornecidas pelo usuário, como:",
                    bullets: [
                        "Nome",
                        "Dados de treino",
                        "Registros de progresso"
                    ]
                ),
                .init(
                    title: "📊 Uso das Informações",
                    introText: "As informações coletadas são usadas para:",
                    bullets: [
                        "Exibir treinos e progresso do aluno.",
                        "Permitir que treinadores acompanhem a evolução dos alunos.",
                        "Melhorar funcionalidades e desempenho do aplicativo."
                    ]
                ),
                .init(
                    title: "🔐 Armazenamento e Segurança",
                    introText: "Os dados são armazenados de forma segura e não são compartilhados com terceiros sem autorização, exceto quando exigido por lei.",
                    bullets: nil
                ),
                .init(
                    title: "🧾 Consentimento",
                    introText: "Ao utilizar este aplicativo, você concorda com esta Política de Privacidade.",
                    bullets: nil
                )
            ]

        case .termsOfUse:
            return [
                .init(
                    title: nil,
                    introText: "Ao utilizar este aplicativo, você concorda com os termos descritos abaixo.",
                    bullets: nil
                ),
                .init(
                    title: "📱 Uso do Aplicativo",
                    introText: "Este aplicativo é destinado ao acompanhamento de treinos físicos entre alunos e treinadores. Ele não substitui orientação médica ou profissional presencial.",
                    bullets: nil
                ),
                .init(
                    title: "⚠️ Responsabilidade",
                    introText: nil,
                    bullets: [
                        "O aluno é responsável por realizar os exercícios respeitando seus limites físicos.",
                        "O treinador é responsável pelas orientações de treino fornecidas.",
                        "O aplicativo atua apenas como uma ferramenta de apoio e registro."
                    ]
                ),
                .init(
                    title: "🚫 Uso Indevido",
                    introText: "É proibido utilizar o aplicativo para fins ilegais, ofensivos ou que prejudiquem outros usuários.",
                    bullets: nil
                ),
                .init(
                    title: "🔄 Alterações",
                    introText: "Os termos podem ser atualizados a qualquer momento para melhorias ou adequações legais. Recomendamos a leitura periódica.",
                    bullets: nil
                ),
                .init(
                    title: "✅ Aceitação",
                    introText: "Ao acessar e utilizar o aplicativo, você declara estar de acordo com estes Termos de Uso.",
                    bullets: nil
                )
            ]
        }
    }
}
