import SwiftUI

/// Recordes publicados de um atleta com perfil público (somente leitura).
/// Exibe apenas categorias e movimentos com resultado salvo; sem edição, exclusão ou inclusão.
struct AthleteRecordsView: View {

    let categories: [AthleteRecordCategory]

    @Environment(\.locale) private var locale
    @AppStorage("preferredWeightUnit") private var preferredWeightUnit: String = "kg"
    @State private var selectedKey: String?

    private var selectedCategory: AthleteRecordCategory? {
        categories.first { $0.key == selectedKey } ?? categories.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if categories.isEmpty {
                Text("athletes.no_records")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.ink(0.55))
                    .frame(maxWidth: .infinity)
                    .personalCard()
            } else {
                categoryChips

                if let category = selectedCategory {
                    ForEach(category.items) { item in
                        recordRow(item)
                    }
                }
            }
        }
    }

    // MARK: - Categorias (somente as que possuem registros)

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    let isSelected = category.key == selectedCategory?.key

                    Button {
                        selectedKey = category.key
                    } label: {
                        Text(LocalizedStringKey("athletes.category.\(category.key)"))
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(
                                isSelected
                                    ? AnyShapeStyle(Color.white)
                                    : AnyShapeStyle(AppThemeColor(dark: Color.white.opacity(0.85), light: PersonalOrganizerLightColors.primaryText))
                            )
                            .background(
                                Capsule().fill(
                                    isSelected
                                        ? AnyShapeStyle(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.55), light: AppThemePalette.lightBar.opacity(0.80)))
                                        : AnyShapeStyle(Theme.Colors.ink(0.10))
                                )
                            )
                            .overlay(
                                Capsule().stroke(
                                    AppThemeColor(
                                        dark: Theme.Colors.primaryGreen.opacity(0.28),
                                        light: PersonalOrganizerLightColors.chevron
                                    ),
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Cartões

    private func recordRow(_ item: AthleteRecordItem) -> some View {
        HStack(spacing: 12) {
            PersonalRowIcon(systemName: "trophy.fill")

            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .modifier(PersonalPrimaryTextStyle())
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            Text(displayValue(item))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppThemeColor(dark: Theme.Colors.primaryGreen, light: PersonalOrganizerLightColors.iconInk))
                .multilineTextAlignment(.trailing)
        }
        .personalCard()
    }

    /// Valores em kg seguem a unidade preferida de quem está visualizando.
    private func displayValue(_ item: AthleteRecordItem) -> String {
        guard item.isWeightKg, let kg = Double(item.value) else { return item.value }

        let useLbs = preferredWeightUnit == "lbs"
        let number = useLbs ? kg * 2.2046226218 : kg

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let text = formatter.string(from: NSNumber(value: number)) ?? String(number)
        return "\(text) \(useLbs ? "lbs" : "kg")"
    }
}

