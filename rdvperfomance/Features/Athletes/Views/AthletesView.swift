import SwiftUI

/// Tela Atletas: busca de usuários cadastrados e lista de favoritos do usuário autenticado.
struct AthletesView: View {

    @Binding var path: [AppRoute]
    let onSelectSection: (StudentMainSection) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @StateObject private var viewModel = AthletesViewModel()

    var body: some View {
        PersonalScreenScaffold(
            titleKey: "athletes.title",
            onBack: { if !path.isEmpty { path.removeLast() } },
            onSelectSection: onSelectSection
        ) {
            searchField

            if let errorKey = viewModel.errorKey {
                PersonalMessageCard(text: AppLocalization.string(String.LocalizationValue(errorKey), locale: locale))
            }

            if viewModel.trimmedQuery.isEmpty {
                favoritesSection
            } else {
                resultsSection
            }
        }
        .task(id: session.uid) {
            await viewModel.loadFavorites(uid: session.uid)
        }
        .onChange(of: viewModel.query) { _, _ in
            viewModel.queryChanged(currentUid: session.uid)
        }
        .onDisappear { viewModel.cancelSearch() }
    }

    // MARK: - Busca

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.ink(0.55))

            TextField("athletes.search_placeholder", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.Colors.ink(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .modifier(PersonalFieldModifier())
    }

    // MARK: - Favoritos

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("athletes.favorites")

            if viewModel.favorites.isEmpty {
                if viewModel.isLoadingFavorites {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .personalCard()
                } else {
                    VStack(spacing: 6) {
                        Text("athletes.empty_favorites_title")
                            .font(.system(size: 14, weight: .semibold))
                            .modifier(PersonalPrimaryTextStyle())

                        Text("athletes.empty_favorites_subtitle")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.ink(0.55))
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .personalCard()
                }
            } else {
                ForEach(viewModel.favorites) { athlete in
                    athleteRow(athlete)
                }
            }
        }
    }

    // MARK: - Resultados

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.isSearching && viewModel.results.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .personalCard()
            } else if viewModel.hasSearched && viewModel.results.isEmpty {
                Text("athletes.no_results")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .frame(maxWidth: .infinity)
                    .personalCard()
            } else {
                ForEach(viewModel.results) { athlete in
                    athleteRow(athlete)
                }
            }
        }
    }

    // MARK: - Componentes

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.Colors.ink(0.55))
            .padding(.horizontal, 6)
    }

    private func athleteRow(_ athlete: PublicAthlete) -> some View {
        let isFavorite = viewModel.favoriteIds.contains(athlete.id)

        return HStack(spacing: 12) {
            Button {
                path.append(.athleteProfile(athleteId: athlete.id))
            } label: {
                HStack(spacing: 12) {
                    UserAvatarView(base64: athlete.photoThumbBase64, size: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(athlete.name)
                            .font(.system(size: 16, weight: .semibold))
                            .modifier(PersonalPrimaryTextStyle())
                            .lineLimit(1)

                        AthletePrivacyBadge(privacy: athlete.privacy)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.toggleFavorite(athlete, uid: session.uid) }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isFavorite
                            ? AnyShapeStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: PersonalOrganizerLightColors.iconInk))
                            : AnyShapeStyle(Theme.Colors.ink(0.45))
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LocalizedStringKey(isFavorite ? "athletes.remove_favorite" : "athletes.add_favorite"))
        }
        .personalCard()
    }
}

/// Indicador de perfil público/privado.
struct AthletePrivacyBadge: View {
    let privacy: AthletePrivacy

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: privacy == .public ? "globe" : "lock.fill")
            Text(LocalizedStringKey(privacy == .public ? "athletes.privacy.public" : "athletes.privacy.private"))
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Theme.Colors.ink(0.55))
    }
}

