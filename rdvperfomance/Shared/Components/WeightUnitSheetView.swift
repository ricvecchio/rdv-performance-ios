import SwiftUI

enum WeightUnit: String, CaseIterable {
    case kg
    case lbs

    var title: String {
        switch self {
        case .kg: return "⚖️ kg (quilograma)"
        case .lbs: return "⚖️ lbs (libra)"
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

            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("Unidade de Medida")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
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
                                        .foregroundColor(.white.opacity(0.92))

                                    Spacer()

                                    if unit == selectedUnit {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.Colors.primaryGreen)
                                            .font(.system(size: 18, weight: .semibold))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.white.opacity(0.25))
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
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    Text("Essa preferência será usada para exibir cargas e referências de treino.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancelar")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onSave) {
                        Text("Salvar")
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
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
