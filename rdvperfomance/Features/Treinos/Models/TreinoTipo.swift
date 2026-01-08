import SwiftUI

// Enum que representa os tipos de treino disponíveis no app
enum TreinoTipo: String, Hashable {

    case crossfit
    case academia
    case emCasa

    // Retorna o nome para exibição na interface
    var displayName: String {
        switch self {
        case .crossfit: return "Crossfit"
        case .academia: return "Academia"
        case .emCasa:   return "Treinos em Casa"
        }
    }

    // Retorna a chave para armazenamento no Firestore
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

    // Retorna o título usado no header das telas
    var titulo: String {
        switch self {
        case .crossfit: return "Treinos Crossfit"
        case .academia: return "Treinos Academia"
        case .emCasa:   return "Treinos em Casa"
        }
    }

    // Retorna o título exibido sobre a imagem
    var tituloOverlayImagem: String {
        displayName
    }

    // Retorna o nome da imagem associada ao tipo
    var imagemCorpo: String {
        switch self {
        case .crossfit: return "rdv_treino1_vertical"
        case .academia: return "rdv_treino2_vertical"
        case .emCasa:   return "rdv_treino3_vertical"
        }
    }

    // Retorna o ícone customizado para o rodapé
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
