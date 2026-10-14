import SwiftUI

enum WeightUnit: String, CaseIterable {
    case kg
    case lbs

    var title: String {
        let locale = Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
        switch self {
        case .kg: return AppLocalization.string("settings.weight_unit.kilograms", locale: locale)
        case .lbs: return AppLocalization.string("settings.weight_unit.pounds", locale: locale)
        }
    }

    var shortLabel: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
}

struct WeightUnitSheetView: View {

    @Binding var selectedUnitRaw: String
    let onCancel: () -> Void
    let onSave: () -> Void

    private var selectedUnit: WeightUnit {
        WeightUnit(rawValue: selectedUnitRaw) ?? .kg
    }

    var body: some View {
        ZStack {

            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Capsule()
                    .fill(Theme.Colors.ink(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("settings.weight_unit.title")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink())
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                    VStack(spacing: 0) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Button {
                                selectedUnitRaw = unit.rawValue
                            } label: {
                                HStack(spacing: 12) {
                                    Text(unit.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Theme.Colors.ink(0.92))

                                    Spacer()

                                    if unit == selectedUnit {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Theme.Colors.icon(Theme.Colors.accentForeground))
                                            .font(.system(size: 18, weight: .semibold))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(Theme.Colors.icon(Theme.Colors.ink(0.25)))
                                            .font(.system(size: 18, weight: .regular))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if unit != WeightUnit.allCases.last {
                                Divider()
                                    .background(Theme.Colors.divider)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.Colors.ink(0.08), lineWidth: 1)
                    )

                    Text("settings.weight_unit.description")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Theme.Colors.ink(0.45))
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.Colors.ink(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onSave) {
                        Text("common.save")
                            .frame(maxWidth: .infinity)
                            .primaryGreenActionButton()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .appThemeNavigationBarColorScheme()
    }
}
