import SwiftUI

/// Estrutura de tela das telas da seção Lembretes: fundo, cabeçalho existente, conteúdo rolável e rodapé
/// do aluno com "Lembretes" selecionado.
struct PersonalScreenScaffold<Content: View, Pinned: View>: View {
    let titleKey: LocalizedStringKey
    let onBack: () -> Void
    let onSelectSection: (StudentMainSection) -> Void
    let pinned: Pinned
    let content: Content

    /// `pinned`: conteúdo opcional fixo no topo (fora da rolagem), ex.: campo de busca que não deve
    /// rolar para trás do cabeçalho quando o teclado é aberto.
    init(
        titleKey: LocalizedStringKey,
        onBack: @escaping () -> Void,
        onSelectSection: @escaping (StudentMainSection) -> Void,
        @ViewBuilder pinned: () -> Pinned,
        @ViewBuilder content: () -> Content
    ) {
        self.titleKey = titleKey
        self.onBack = onBack
        self.onSelectSection = onSelectSection
        self.pinned = pinned()
        self.content = content()
    }

    @EnvironmentObject private var session: AppSession

    /// Aluno: rodapé com Menu destacado. Professor: rodapé Home | Menu | Perfil (Menu destacado pelo ambiente).
    private var footerKind: FooterBar.Kind {
        if session.isTrainer {
            return .teacherHomeAlunosSobrePerfil(
                selectedCategory: .crossfit,
                isHomeSelected: false,
                isAlunosSelected: false,
                isSobreSelected: false,
                isPerfilSelected: false
            )
        }
        return .studentHomeTreinosRecordsProfile(
            isHomeSelected: false,
            isTreinosSelected: false,
            isRecordsSelected: false,
            isPerfilSelected: false,
            isRemindersSelected: true
        )
    }

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        ZStack {

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                if Pinned.self != EmptyView.self {
                    HStack {
                        Spacer(minLength: 0)

                        pinned
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            content
                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, Pinned.self == EmptyView.self ? 16 : 14)

                        Spacer(minLength: 0)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                FooterBar(
                    path: .constant([]),
                    kind: footerKind,
                    onSelectStudentSection: onSelectSection
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        // O fundo fica em `.background` (e não como filho do ZStack): a imagem usa scaledToFill e, no Tema Claro
        // (900×1600, mais alta que larga), ultrapassava a altura reduzida pelo teclado, aumentando o ZStack e
        // deslocando o conteúdo para trás do cabeçalho. Em `.background` ela não participa do layout.
        .background { AppThemeBackgroundImage() }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text(titleKey)
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
    }
}

extension PersonalScreenScaffold where Pinned == EmptyView {
    init(
        titleKey: LocalizedStringKey,
        onBack: @escaping () -> Void,
        onSelectSection: @escaping (StudentMainSection) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            titleKey: titleKey,
            onBack: onBack,
            onSelectSection: onSelectSection,
            pinned: { EmptyView() },
            content: content
        )
    }
}

/// Mensagem de erro/aviso estilizada.
struct PersonalMessageCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow.opacity(0.85))

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.ink(0.75))

            Spacer()
        }
        .personalCard()
    }
}

/// Botão de ação do topo de cada lista (ex.: "Nova anotação").
struct PersonalAddButton: View {
    let titleKey: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text(titleKey)
            }
            .frame(maxWidth: .infinity)
            .modifier(PersonalPrimaryButtonModifier())
        }
        .buttonStyle(.plain)
    }
}

/// Formatação de datas localizada para a seção Lembretes.
enum PersonalDateFormat {
    /// "15 de março" (dia e mês; inclui 29/02).
    static func dayMonth(day: Int, month: Int, locale: Locale) -> String {
        var components = DateComponents()
        components.year = 2000 // ano bissexto: aceita 29/02
        components.month = month
        components.day = day
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else { return "\(day)/\(month)" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("dMMMM")
        return formatter.string(from: date)
    }

    /// "15 de março de 1965" (dia, mês e ano de nascimento informado).
    static func dayMonthYear(day: Int, month: Int, year: Int, locale: Locale) -> String {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components),
              calendar.component(.day, from: date) == day else {
            return dayMonth(day: day, month: month, locale: locale)
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("dMMMMyyyy")
        return formatter.string(from: date)
    }

    static func dateTime(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("ddMMMyyyyHHmm")
        return formatter.string(from: date)
    }

    static func monthNames(locale: Locale) -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar.standaloneMonthSymbols.map { $0.prefix(1).uppercased() + $0.dropFirst() }
    }
}

