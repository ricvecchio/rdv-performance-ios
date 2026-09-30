import SwiftUI

/// Enumeração dos tipos de treino disponíveis no aplicativo
enum TreinoTipo: String, Hashable {

    case crossfit
    case academia
    case emCasa

    /// Retorna o nome de exibição do tipo de treino
    var displayName: String {
        switch self {
        case .crossfit: return String(localized: "Crossfit", locale: Self.localizationLocale)
        case .academia: return String(localized: "Academia", locale: Self.localizationLocale)
        case .emCasa:   return String(localized: "Treinos em Casa", locale: Self.localizationLocale)
        }
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
        switch self {
        case .crossfit: return String(localized: "Treinos Crossfit", locale: Self.localizationLocale)
        case .academia: return String(localized: "Treinos Academia", locale: Self.localizationLocale)
        case .emCasa:   return String(localized: "Treinos em Casa", locale: Self.localizationLocale)
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
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
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
