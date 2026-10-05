import SwiftUI

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

    /// Sempre fornecido pelo `StudentRootView`. Usado tanto pelo rodapé
    /// quanto pelo botão `<` desta tela: como esta view é a RAIZ da seção
    /// Recordes, `path` está sempre vazio aqui — não existe nada para dar
    /// pop. "Voltar" nesta tela sempre significa "trocar para a seção Treinos".
    var onSelectSection: (StudentMainSection) -> Void = { _ in }
    var navigationContext: PersonalRecordsNavigationContext = .student

    private let contentMaxWidth: CGFloat = 380
    private let repository = FirestoreRepository.shared
    @State private var isTecnofitImportPresented = false
    @State private var hasCompletedTecnofitImport = false
    @State private var hasLoadedTecnofitImportStatus = false

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
        .init(title: "Gymnastic", localizedTitle: "personal_records_gymnastic.gymnastic", sectionKey: "gymnastic", icon: "circle.circle"),
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

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 8) {

                            if hasLoadedTecnofitImportStatus && !hasCompletedTecnofitImport {
                                tecnofitImportButton
                            }

                            VStack(spacing: 6) {
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

                                if case .student = navigationContext {
                                    actionRow(
                                        title: "Meus Vídeos",
                                        localizedTitle: "workout.my_videos",
                                        icon: "video.fill"
                                    ) {
                                        path.append(.studentVideos)
                                    }
                                }
                            }

                            Color.clear.frame(height: Theme.Layout.footerHeight + 20)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        Spacer(minLength: 0)
                    }
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
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("personal_records.personal_record")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
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
                        .fill(Color.green.opacity(0.14))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .foregroundColor(.green.opacity(0.85))
                        .font(.system(size: 16, weight: .semibold))
                }

                Group {
                    if let localizedTitle {
                        Text(LocalizedStringKey(localizedTitle))
                    } else {
                        Text(title)
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(2)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var tecnofitImportButton: some View {
        Button {
            isTecnofitImportPresented = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                Text("personal_records.import_from_tecnofit")
            }
            .padding(.horizontal, 14)
            .compactPrimaryGreenActionButton()
        }
        .buttonStyle(.plain)
    }

    private func loadTecnofitImportStatus() async {
        hasLoadedTecnofitImportStatus = false
        hasCompletedTecnofitImport = false

        guard let uid = session.currentUid?.trimmingCharacters(in: .whitespacesAndNewlines),
              !uid.isEmpty
        else {
            return
        }

        do {
            let hasCompletedImport = try await repository.hasCompletedTecnofitImport(uid: uid)
            guard !Task.isCancelled, session.currentUid == uid else { return }
            hasCompletedTecnofitImport = hasCompletedImport
            hasLoadedTecnofitImportStatus = true
        } catch {
        }
    }

}
