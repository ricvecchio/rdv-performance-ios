import SwiftUI

// Tela de seleção do tema do aplicativo (Escuro / Claro)
struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.storageKey) private var selectedAppTheme = AppTheme.defaultTheme.rawValue

    private let contentMaxWidth: CGFloat = 380

    private var currentTheme: AppTheme {
        AppTheme(storedValue: selectedAppTheme)
    }

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
                            Text("settings.theme.description")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.Colors.ink(0.6))
                                .padding(.horizontal, 6)

                            themeCard()

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
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("settings.theme.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeCard() -> some View {
        VStack(spacing: 0) {
            ForEach(AppTheme.allCases) { theme in
                themeRow(theme)

                if theme != AppTheme.allCases.last {
                    Divider()
                        .background(Theme.Colors.divider)
                        .padding(.leading, 54)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.glass(0.68))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
        )
    }

    private func themeRow(_ theme: AppTheme) -> some View {
        let isSelected = currentTheme == theme

        return Button {
            selectedAppTheme = theme.rawValue
        } label: {
            HStack(spacing: 14) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(.green.opacity(0.85))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.localizedTitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink(0.92))

                    Text(theme.localizedDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(Color.green)
                            : AnyShapeStyle(Theme.Colors.ink(0.35))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

