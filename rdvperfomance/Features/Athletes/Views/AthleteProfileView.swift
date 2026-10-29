import SwiftUI

/// Perfil de outro atleta. Mostra somente dados públicos mínimos (foto, nome, privacidade e quantidade de PRs).
/// Os recordes só são exibidos (somente leitura) quando o atleta optou pelo perfil público.
struct AthleteProfileView: View {

    private enum Tab: Hashable {
        case profile
        case records
    }

    @Binding var path: [AppRoute]
    let athleteId: String
    let onSelectSection: (StudentMainSection) -> Void

    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale
    @StateObject private var viewModel = AthleteProfileViewModel()
    @State private var tab: Tab = .profile

    var body: some View {
        PersonalScreenScaffold(
            titleKey: "athletes.profile_title",
            onBack: { if !path.isEmpty { path.removeLast() } },
            onSelectSection: onSelectSection
        ) {
            if let errorKey = viewModel.errorKey {
                PersonalMessageCard(text: AppLocalization.string(errorKey, locale: locale))
            }

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .personalCard()

            case .unavailable:
                messageCard("athletes.unavailable")

            case .failed:
                messageCard("athletes.error.generic")

            case .loaded:
                if let athlete = viewModel.athlete {
                    content(for: athlete)
                }
            }
        }
        .task(id: athleteId) {
            await viewModel.load(athleteId: athleteId, currentUid: session.uid)
        }
        // Reavalia o acesso ao voltar para a aba de recordes (a privacidade pode ter mudado).
        .onChange(of: tab) { _, newValue in
            if newValue == .records {
                Task { await viewModel.loadRecords(athleteId: athleteId) }
            }
        }
    }

    // MARK: - Conteúdo

    @ViewBuilder
    private func content(for athlete: PublicAthlete) -> some View {
        headerCard(athlete)

        if athlete.privacy == .public {
            Picker("", selection: $tab) {
                Text("athletes.tab.profile").tag(Tab.profile)
                Text("athletes.tab.prs").tag(Tab.records)
            }
            .pickerStyle(.segmented)
        }

        if athlete.privacy == .public && tab == .records {
            if viewModel.recordsAccessDenied {
                messageCard("athletes.private_message")
            } else {
                AthleteRecordsView(categories: viewModel.categories)
            }
        } else {
            prCountCard(athlete)

            if athlete.privacy == .private {
                messageCard("athletes.private_message")
            }
        }
    }

    private func headerCard(_ athlete: PublicAthlete) -> some View {
        VStack(spacing: 10) {
            UserAvatarView(base64: athlete.photoThumbBase64, size: 88)

            Text(athlete.name)
                .font(.system(size: 20, weight: .bold))
                .modifier(PersonalPrimaryTextStyle())
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Text("athletes.badge_athlete")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink(0.55))

                AthletePrivacyBadge(privacy: athlete.privacy)
            }

            Button {
                Task { await viewModel.toggleFavorite(currentUid: session.uid) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                    Text(LocalizedStringKey(viewModel.isFavorite ? "athletes.remove_favorite" : "athletes.add_favorite"))
                }
                .frame(maxWidth: .infinity)
                .modifier(PersonalPrimaryButtonModifier())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .personalCard()
    }

    private func prCountCard(_ athlete: PublicAthlete) -> some View {
        HStack(spacing: 12) {
            PersonalRowIcon(systemName: "trophy.fill")

            Text("athletes.pr_count \(athlete.prCount)")
                .font(.system(size: 16, weight: .semibold))
                .modifier(PersonalPrimaryTextStyle())

            Spacer(minLength: 0)
        }
        .personalCard()
    }

    private func messageCard(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 14))
            .foregroundStyle(Theme.Colors.ink(0.55))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .personalCard()
    }
}

