import SwiftUI

/// Estrutura de tela das telas da seção Lembretes: fundo, cabeçalho existente, conteúdo rolável e rodapé
/// do aluno com "Lembretes" selecionado.
struct PersonalScreenScaffold<Content: View>: View {
    let titleKey: LocalizedStringKey
    let onBack: () -> Void
    let onSelectSection: (StudentMainSection) -> Void
    @ViewBuilder let content: Content

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        ZStack {
            AppThemeBackgroundImage()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 14) {
                            content
                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                FooterBar(
                    path: .constant([]),
                    kind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: false,
                        isTreinosSelected: false,
                        isRecordsSelected: false,
                        isPerfilSelected: false,
                        isRemindersSelected: true
                    ),
                    onSelectStudentSection: onSelectSection
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
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

