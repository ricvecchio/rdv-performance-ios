import SwiftUI

/// Privacidade do perfil: define se outros atletas podem ver os recordes pessoais (recurso Atletas).
/// Valor padrão: Privado. Afeta somente a visualização compartilhada pelo recurso Atletas.
struct ProfilePrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var appTheme
    @Environment(\.locale) private var locale
    @EnvironmentObject private var session: AppSession

    @State private var privacy: AthletePrivacy = .private
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorKey: String?

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

                        VStack(alignment: .leading, spacing: 16) {
                            if let errorKey {
                                PersonalMessageCard(text: AppLocalization.string(String.LocalizationValue(errorKey), locale: locale))
                            }

                            VStack(spacing: 0) {
                                option(.public, titleKey: "settings.privacy.public.title", descriptionKey: "settings.privacy.public.description")

                                Divider()
                                    .background(Theme.Colors.divider)
                                    .padding(.leading, 54)

                                option(.private, titleKey: "settings.privacy.private.title", descriptionKey: "settings.privacy.private.description")
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .modifier(PrivacyCardSurface())
                            .opacity(isLoading ? 0.6 : 1)

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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
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
                Text("settings.privacy.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }
        }
        .toolbarBackground(Theme.Colors.headerBackgroundColor(for: appTheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadPrivacy() }
    }

    private func option(
        _ value: AthletePrivacy,
        titleKey: LocalizedStringKey,
        descriptionKey: LocalizedStringKey
    ) -> some View {
        let isSelected = privacy == value

        return Button {
            Task { await select(value) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: value == .public ? "globe" : "lock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: PersonalOrganizerLightColors.iconInk))
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(titleKey)
                        .font(.system(size: 17, weight: .medium))
                        .modifier(PersonalPrimaryTextStyle())

                    Text(descriptionKey)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(AppThemeColor(dark: Color.green, light: PersonalOrganizerLightColors.iconInk))
                            : AnyShapeStyle(Theme.Colors.icon(Theme.Colors.ink(0.35)))
                    )
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isSaving)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func loadPrivacy() async {
        guard let uid = session.uid, !uid.isEmpty else {
            isLoading = false
            return
        }

        do {
            // Sem documento público ainda: considerado privado (padrão).
            privacy = try await AthletesService.shared.athlete(id: uid)?.privacy ?? .private
        } catch {
            errorKey = "settings.privacy.error"
        }
        isLoading = false
    }

    private func select(_ value: AthletePrivacy) async {
        guard value != privacy, let uid = session.uid, !uid.isEmpty else { return }

        let previous = privacy
        privacy = value
        isSaving = true
        errorKey = nil

        do {
            try await AthletesService.shared.setPrivacy(uid: uid, privacy: value)
        } catch {
            privacy = previous
            errorKey = "settings.privacy.error"
        }

        isSaving = false
    }
}

/// Mesmo acabamento do card da tela de Tema.
private struct PrivacyCardSurface: ViewModifier {
    @Environment(\.appTheme) private var appTheme

    func body(content: Content) -> some View {
        content
            .background(AppThemeColor(dark: Color.black.opacity(0.68), light: Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: PersonalOrganizerLightColors.chevron),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: appTheme == .light ? .black.opacity(0.25) : .clear,
                radius: appTheme == .light ? 10 : 0,
                y: appTheme == .light ? 6 : 0
            )
    }
}

