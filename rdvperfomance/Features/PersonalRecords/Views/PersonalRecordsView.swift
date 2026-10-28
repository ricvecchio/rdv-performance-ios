import SwiftUI
import UIKit

enum PersonalRecordsNavigationContext {
    case student
    case teacher(category: TreinoTipo)
}

struct PersonalRecordsFooter: View {
    @Binding var path: [AppRoute]
    let navigationContext: PersonalRecordsNavigationContext
    let studentFooterKind: FooterBar.Kind
    let onSelectStudentSection: (StudentMainSection) -> Void

    var body: some View {
        switch navigationContext {
        case .student:
            FooterBar(
                path: $path,
                kind: studentFooterKind,
                onSelectStudentSection: onSelectStudentSection
            )
        case .teacher(let category):
            FooterBar(
                path: $path,
                kind: .teacherHomeAlunosSobrePerfil(
                    selectedCategory: category,
                    isHomeSelected: false,
                    isAlunosSelected: false,
                    isSobreSelected: false,
                    isPerfilSelected: false
                )
            )
        }
    }
}

// Tela compartilhada de Recordes Pessoais.
struct PersonalRecordsView: View {

    @Binding var path: [AppRoute]
    let onBack: () -> Void
    @EnvironmentObject private var session: AppSession
    @Environment(\.appTheme) private var appTheme

    /// Sempre fornecido pelo `StudentRootView`. Usado tanto pelo rodapé
    /// quanto pelo botão `<` desta tela: como esta view é a RAIZ da seção
    /// Recordes, `path` está sempre vazio aqui — não existe nada para dar
    /// pop. "Voltar" nesta tela sempre significa "trocar para a seção Treinos".
    var onSelectSection: (StudentMainSection) -> Void = { _ in }
    var navigationContext: PersonalRecordsNavigationContext = .student

    private let contentMaxWidth: CGFloat = 380
    private let repository = FirestoreRepository.shared

    // Cores locais exclusivas do Tema Claro dos cards do menu (Tema Escuro usa sempre os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let cardBorder = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)   // #C9DFC9
        static let iconSurface = Color(red: 0x85 / 255, green: 0xC9 / 255, blue: 0x95 / 255)  // #85C995
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)      // #294A2F
    }
    @State private var isTecnofitImportPresented = false
    @State private var hasCompletedTecnofitImport = false
    @State private var hasLoadedTecnofitImportStatus = false
    /// Indica que a consulta do status terminou (com sucesso, erro ou sem usuário). Enquanto for `false`,
    /// a lista de cards não é exibida, para não mostrar um espaçamento provisório que seria trocado em seguida.
    @State private var hasFinishedTecnofitImportCheck = false

    private struct PRMenuItem: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let localizedTitle: String?
        let sectionKey: String
        let icon: String

        init(title: String, localizedTitle: String? = nil, sectionKey: String, icon: String) {
            self.title = title
            self.localizedTitle = localizedTitle
            self.sectionKey = sectionKey
            self.icon = icon
        }
    }

    // Itens fixos conforme solicitado (ordem + nomes)
    private let menuItems: [PRMenuItem] = [
        .init(title: "Barbell", localizedTitle: "personal_records_barbell.barbell", sectionKey: "barbell", icon: "dumbbell.fill"),
        .init(title: "Gymnastic", localizedTitle: "personal_records_gymnastic.gymnastic", sectionKey: "gymnastic", icon: "gymnastic_rings"),
        .init(title: "Endurance", localizedTitle: "personal_records_endurance.endurance", sectionKey: "endurance", icon: "figure.run"),
        .init(title: "Notables", localizedTitle: "personal_records_notables.notables", sectionKey: "notables", icon: "star.fill"),
        .init(title: "Girls", localizedTitle: "personal_records_girls.girls", sectionKey: "girls", icon: "figure.strengthtraining.traditional"),
        .init(title: "Open", localizedTitle: "personal_records_open.open", sectionKey: "open", icon: "flag.checkered"),
        .init(title: "The Heroes", localizedTitle: "personal_records_heroes.the_heroes", sectionKey: "theHeroes", icon: "shield.fill"),
        .init(title: "Campeonatos", localizedTitle: "personal_records_campeonatos.championships", sectionKey: "campeonatos", icon: "trophy.fill"),
        .init(title: "Crossfit Games", localizedTitle: "personal_records_crossfit_games.crossfit_games", sectionKey: "crossfitGames", icon: "globe")
    ]

    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                GeometryReader { geometry in
                    let distributedSpacing = distributedCardSpacing(availableHeight: geometry.size.height)

                    ScrollView(showsIndicators: false) {
                        HStack {
                            Spacer(minLength: 0)

                            VStack(alignment: .leading, spacing: 8) {


                                VStack(spacing: distributedSpacing ?? Self.defaultCardSpacing) {
                                    ForEach(menuItems) { item in
                                        actionRow(
                                            title: item.title,
                                            localizedTitle: item.localizedTitle,
                                            icon: item.icon
                                        ) {

                                            if item.sectionKey == "barbell" {
                                                path.append(.studentPersonalRecordsBarbell)
                                            }

                                            if item.sectionKey == "gymnastic" {
                                                path.append(.studentPersonalRecordsGymnastic)
                                            }

                                            if item.sectionKey == "endurance" {
                                                path.append(.studentPersonalRecordsEndurance)
                                            }

                                            if item.sectionKey == "notables" {
                                                path.append(.studentPersonalRecordsNotables)
                                            }

                                            if item.sectionKey == "girls" {
                                                path.append(.studentPersonalRecordsGirls)
                                            }

                                            if item.sectionKey == "open" {
                                                path.append(.studentPersonalRecordsOpen)
                                            }

                                            if item.sectionKey == "theHeroes" {
                                                path.append(.studentPersonalRecordsHeroes)
                                            }

                                            if item.sectionKey == "campeonatos" {
                                                path.append(.studentPersonalRecordsCampeonatos)
                                            }

                                            if item.sectionKey == "crossfitGames" {
                                                path.append(.studentPersonalRecordsCrossfitGames)
                                            }
                                        }
                                    }
                                }

                                // Com espaçamento distribuído o rodapé já é um irmão da rolagem (não sobrepõe);
                                // caso contrário mantém a reserva original.
                                Color.clear.frame(
                                    height: distributedSpacing != nil
                                        ? Self.distributedBottomMargin
                                        : Theme.Layout.footerHeight + 20
                                )
                            }
                            .frame(maxWidth: contentMaxWidth)
                            .padding(.horizontal, 16)
                            .padding(.top, Self.contentTopPadding)

                            Spacer(minLength: 0)
                        }
                    }
                    // Só a lista aguarda o status inicial: o layout definitivo aparece de uma vez
                    .opacity(hasFinishedTecnofitImportCheck ? 1 : 0)
                    .allowsHitTesting(hasFinishedTecnofitImportCheck)
                }

                PersonalRecordsFooter(
                    path: $path,
                    navigationContext: navigationContext,
                    studentFooterKind: .studentHomeTreinosRecordsProfile(
                        isHomeSelected: false,
                        isTreinosSelected: false,
                        isRecordsSelected: true,
                        isPerfilSelected: false
                    ),
                    onSelectStudentSection: onSelectSection
                )
                .frame(height: Theme.Layout.footerHeight)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isTecnofitImportPresented) {
            TecnofitImportSheet {
                hasCompletedTecnofitImport = true
            }
        }
        .task(id: session.currentUid) {
            await loadTecnofitImportStatus()
        }
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
                Text("personal_records.personal_record")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Importar do Tecnofit: somente após a consulta confirmar que a importação está pendente
                    if hasLoadedTecnofitImportStatus && !hasCompletedTecnofitImport {
                        Button {
                            isTecnofitImportPresented = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("tecnofit_import.import_action")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink(0.92))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.green.opacity(0.16)))
                        }
                        .buttonStyle(.plain)
                    }

                    HeaderAvatarView(size: 38)
                }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
        .navigationBarTitleDisplayMode(.inline)
    }

    // Espaçamento original entre os cards e parâmetros da distribuição vertical
    private static let defaultCardSpacing: CGFloat = 6
    private static let contentTopPadding: CGFloat = 8
    private static let distributedBottomMargin: CGFloat = 16
    private static let contentStackSpacing: CGFloat = 8
    /// Altura de cada card: minHeight (52) + padding vertical (4 + 4) de `actionRow`.
    private static let cardRowHeight: CGFloat = 60

    /// Espaçamento uniforme para distribuir os cards na altura útil, somente quando a verificação do
    /// Importar Tecnofit já terminou e o botão não é mais exibido. Retorna `nil` nos demais casos
    /// (carregando, botão visível ou sem espaço extra), mantendo o layout original.
    private func distributedCardSpacing(availableHeight: CGFloat) -> CGFloat? {
        guard menuItems.count > 1 else {
            return nil
        }

        let itemsHeight = CGFloat(menuItems.count) * Self.cardRowHeight
        let reserved = Self.contentTopPadding + Self.contentStackSpacing + Self.distributedBottomMargin
        let freeHeight = availableHeight - reserved - itemsHeight
        let spacing = freeHeight / CGFloat(menuItems.count - 1)

        guard spacing.isFinite, spacing > Self.defaultCardSpacing else { return nil }
        return spacing
    }

    private func actionRow(
        title: String,
        localizedTitle: String? = nil,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(AppThemeColor(dark: Color.green.opacity(0.14), light: LightColors.iconSurface))
                        .frame(width: 34, height: 34)

                    if UIImage(named: icon) != nil {
                        Image(icon)
                            .renderingMode(.template)
                            .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.iconInk))
                    } else {
                        Image(systemName: icon)
                            .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.iconInk))
                            .font(.system(size: 16, weight: .semibold))
                    }
                }

                Group {
                    if let localizedTitle {
                        Text(LocalizedStringKey(localizedTitle))
                    } else {
                        Text(title)
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                .lineLimit(2)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.35), light: LightColors.chevron))
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    // Mesma tonalidade dos botões da TeacherWorkoutsView
                    // Tema Claro: verde pastel solido, sem sobreposicao
                    AppThemeColor(dark: Color.black.opacity(0.90), light: LightColors.cardSurface)
                    AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.05), light: .clear)
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.chevron), lineWidth: 1)
            )
            // Tema Claro: mesma profundidade dos botoes da AdminProfileSelectionView (Tema Escuro: sem sombra)
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }


    private func loadTecnofitImportStatus() async {
        hasLoadedTecnofitImportStatus = false
        hasCompletedTecnofitImport = false
        hasFinishedTecnofitImportCheck = false

        guard let uid = session.currentUid?.trimmingCharacters(in: .whitespacesAndNewlines),
              !uid.isEmpty
        else {
            // Sem usuário: não há consulta a aguardar; mantém o comportamento atual (sem botão)
            hasFinishedTecnofitImportCheck = true
            return
        }

        do {
            let hasCompletedImport = try await repository.hasCompletedTecnofitImport(uid: uid)
            guard !Task.isCancelled, session.currentUid == uid else { return }
            hasCompletedTecnofitImport = hasCompletedImport
            hasLoadedTecnofitImportStatus = true
            hasFinishedTecnofitImportCheck = true
        } catch {
            // Erro: não assume importação concluída nem exibe o botão; apenas libera a lista
            // (se a tarefa foi cancelada/trocou de usuário, a nova consulta libera a lista).
            guard !Task.isCancelled, session.currentUid == uid else { return }
            hasFinishedTecnofitImportCheck = true
        }
    }

}
