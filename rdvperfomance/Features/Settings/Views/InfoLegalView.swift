// Tela reutilizável para exibir conteúdos legais e de ajuda
import SwiftUI

// Modelo para seções de conteúdo informativo
struct InfoLegalSection: Hashable {
    let title: String?
    let introText: String?
    let bullets: [String]?
}

// View que exibe diferentes tipos de conteúdo legal baseado no tipo
struct InfoLegalView: View {

    @Binding var path: [AppRoute]

    let kind: InfoLegalKind

    private let contentMaxWidth: CGFloat = 380

    init(
        path: Binding<[AppRoute]>,
        kind: InfoLegalKind,
        onSelectSection: @escaping (StudentMainSection) -> Void = { _ in }
    ) {
        _path = path
        self.kind = kind
        _ = onSelectSection
    }

    // Constrói a interface com conteúdo legal
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

            }
            .ignoresSafeArea(.container, edges: [.bottom])
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
                Text(LocalizedStringKey(kind.screenTitle))
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Retorna card com as seções de conteúdo formatadas
    private func contentCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {

            ForEach(kind.sections, id: \.self) { section in

                if let title = section.title {
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }

                if let intro = section.introText {
                    Text(LocalizedStringKey(intro))
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
                                Text(LocalizedStringKey(b))
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

// Define títulos e conteúdo para cada tipo de informação legal
private extension InfoLegalKind {

    // Retorna o título da tela
    var screenTitle: String {
        switch self {
        case .helpCenter: return "settings.help_center"
        case .privacyPolicy: return "settings.privacy_policy"
        case .termsOfUse: return "settings.terms_of_use"
        }
    }

    // Retorna o título do corpo do conteúdo
    var bodyTitle: String {
        switch self {
        case .helpCenter: return "settings.help_center"
        case .privacyPolicy: return "settings.legal.privacy.body_title"
        case .termsOfUse: return "settings.terms_of_use"
        }
    }

    // Retorna as seções de conteúdo formatadas
    var sections: [InfoLegalSection] {
        switch self {

        case .helpCenter:
            return [
                .init(
                    title: nil,
                    introText: """
settings.legal.help.introduction
""",
                    bullets: nil
                ),
                .init(title: "settings.legal.help.students.title", introText: nil, bullets: [
                    "settings.legal.help.students.view_workouts",
                    "settings.legal.help.students.complete_exercises",
                    "settings.legal.help.students.track_progress",
                    "settings.legal.help.students.record_progress"
                ]),
                .init(title: "settings.legal.help.trainers.title", introText: nil, bullets: [
                    "settings.legal.help.trainers.create_workouts",
                    "settings.legal.help.trainers.track_students",
                    "settings.legal.help.trainers.support_training"
                ]),
                .init(
                    title: "settings.legal.help.faq.title",
                    introText: """
settings.legal.help.faq.introduction
""",
                    bullets: [
                        "settings.legal.help.faq.account_connected",
                        "settings.legal.help.faq.internet_connection",
                        "settings.legal.help.faq.latest_version"
                    ]
                ),
                .init(
                    title: "settings.legal.help.support.title",
                    introText: """
settings.legal.help.support.contact
""",
                    bullets: nil
                )
            ]

        case .privacyPolicy:
            return [
                .init(
                    title: nil,
                    introText: """
settings.legal.privacy.introduction
""",
                    bullets: nil
                ),
                .init(
                    title: "settings.legal.privacy.collection.title",
                    introText: "settings.legal.privacy.collection.introduction",
                    bullets: [
                        "common.name",
                        "settings.legal.privacy.collection.workout_data",
                        "settings.legal.privacy.collection.progress_records"
                    ]
                ),
                .init(
                    title: "settings.legal.privacy.usage.title",
                    introText: "settings.legal.privacy.usage.introduction",
                    bullets: [
                        "settings.legal.privacy.usage.display_progress",
                        "settings.legal.privacy.usage.trainer_progress",
                        "settings.legal.privacy.usage.improve_app"
                    ]
                ),
                .init(
                    title: "settings.legal.privacy.storage.title",
                    introText: "settings.legal.privacy.storage.description",
                    bullets: nil
                ),
                .init(
                    title: "settings.legal.privacy.consent.title",
                    introText: "settings.legal.privacy.consent.description",
                    bullets: nil
                )
            ]

        case .termsOfUse:
            return [
                .init(
                    title: nil,
                    introText: "settings.legal.terms.introduction",
                    bullets: nil
                ),
                .init(
                    title: "settings.legal.terms.usage.title",
                    introText: "settings.legal.terms.usage.description",
                    bullets: nil
                ),
                .init(
                    title: "settings.legal.terms.responsibility.title",
                    introText: nil,
                    bullets: [
                        "settings.legal.terms.responsibility.student",
                        "settings.legal.terms.responsibility.trainer",
                        "settings.legal.terms.responsibility.app"
                    ]
                ),
                .init(
                    title: "settings.legal.terms.misuse.title",
                    introText: "settings.legal.terms.misuse.description",
                    bullets: nil
                ),
                .init(
                    title: "settings.legal.terms.changes.title",
                    introText: "settings.legal.terms.changes.description",
                    bullets: nil
                ),
                .init(
                    title: "settings.legal.terms.acceptance.title",
                    introText: "settings.legal.terms.acceptance.description",
                    bullets: nil
                )
            ]
        }
    }
}
