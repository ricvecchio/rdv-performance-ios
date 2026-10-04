import SwiftUI

/// Enumeração dos tipos de treino disponíveis no aplicativo
enum TreinoTipo: String, Hashable {

    case crossfit
    case academia
    case emCasa

    /// Retorna o nome de exibição do tipo de treino
    var displayName: String {
        localizedDisplayName(locale: Self.localizationLocale)
    }

    /// Retorna a chave usada para armazenar o tipo no Firestore
    var firestoreKey: String {
        switch self {
        case .crossfit: return "CROSSFIT"
        case .academia: return "ACADEMIA"
        case .emCasa:   return "EMCASA"
        }
    }

    // Normaliza strings variadas para o enum correto
    static func normalized(from any: String) -> TreinoTipo? {
        let v = any.trimmingCharacters(in: .whitespacesAndNewlines)

        if let t = TreinoTipo(rawValue: v) { return t }

        let lower = v.lowercased()
        if let t = TreinoTipo(rawValue: lower) { return t }

        let upper = v.uppercased()
        switch upper {
        case "CROSSFIT": return .crossfit
        case "ACADEMIA": return .academia
        case "EMCASA", "EM_CASA", "EM CASA": return .emCasa
        default: return nil
        }
    }

    /// Retorna o título completo usado no cabeçalho das telas
    var titulo: String {
        localizedTitle(locale: Self.localizationLocale)
    }

    func localizedDisplayName(locale: Locale) -> String {
        switch self {
        case .crossfit: return AppLocalization.string("video.category.crossfit", locale: locale)
        case .academia: return AppLocalization.string("video.category.gym", locale: locale)
        case .emCasa: return AppLocalization.string("ui.home_workouts", locale: locale)
        }
    }

    func localizedTitle(locale: Locale) -> String {
        switch self {
        case .crossfit: return AppLocalization.string("ui.crossfit_workouts", locale: locale)
        case .academia: return AppLocalization.string("ui.gym_workouts", locale: locale)
        case .emCasa: return AppLocalization.string("ui.home_workouts", locale: locale)
        }
    }

    /// Retorna o título exibido sobre a imagem do tipo de treino
    var tituloOverlayImagem: String {
        displayName
    }

    /// Retorna o nome do asset da imagem associada ao tipo de treino
    var imagemCorpo: String {
        switch self {
        case .crossfit: return "rdv_treino1_vertical"
        case .academia: return "rdv_treino2_vertical"
        case .emCasa:   return "rdv_treino3_vertical"
        }
    }

    private static var localizationLocale: Locale {
        .autoupdatingCurrent
    }

    /// Retorna o ícone customizado usado no rodapé da tela
    @ViewBuilder
    var iconeRodapeTreinos: some View {
        switch self {
        case .crossfit:
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 20))

        case .academia:
            Image(systemName: "dumbbell")
                .font(.system(size: 20))

        case .emCasa:
            ZStack {
                Image(systemName: "house")
                    .font(.system(size: 20))

                Image(systemName: "dumbbell")
                    .font(.system(size: 11))
                    .offset(y: 4)
            }
        }
    }
}
