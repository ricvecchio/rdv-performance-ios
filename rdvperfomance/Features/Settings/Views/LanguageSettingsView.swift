import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case portugueseBrazil = "pt-BR"
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var flagAssetName: String {
        switch self {
        case .portugueseBrazil:
            "flag_br"
        case .english:
            "flag_us"
        case .spanish:
            "flag_es"
        }
    }

    var localizedName: LocalizedStringKey {
        switch self {
        case .portugueseBrazil:
            "settings.language.portuguese_brazil"
        case .english:
            "settings.language.english"
        case .spanish:
            "settings.language.spanish"
        }
    }
}

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedAppLanguage") private var selectedAppLanguage = AppLanguage.portugueseBrazil.rawValue

    private let contentMaxWidth: CGFloat = 380

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
                            languageCard()

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
                Text("settings.language.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func languageCard() -> some View {
        VStack(spacing: 0) {
            ForEach(AppLanguage.allCases) { language in
                languageRow(language)

                if language != .spanish {
                    Divider()
                        .background(Theme.Colors.divider)
                        .padding(.leading, 54)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            selectedAppLanguage = language.rawValue
        } label: {
            HStack(spacing: 14) {
                Image(language.flagAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                Text(language.localizedName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Image(systemName: selectedAppLanguage == language.rawValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selectedAppLanguage == language.rawValue ? .green : .white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
