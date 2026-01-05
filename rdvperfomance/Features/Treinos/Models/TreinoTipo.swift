import SwiftUI

// TreinoTipo.swift — Enum que representa tipos de treino e fornece helpers de UI/serialização
enum TreinoTipo: String, Hashable {

    case crossfit
    case academia
    case emCasa

    // Nome curto exibido na UI
    var displayName: String {
        switch self {
        case .crossfit: return "Crossfit"
        case .academia: return "Academia"
        case .emCasa:   return "Treinos em Casa"
        }
    }

    // Chave padronizada para armazenamento no Firestore
    var firestoreKey: String {
        switch self {
        case .crossfit: return "CROSSFIT"
        case .academia: return "ACADEMIA"
        case .emCasa:   return "EMCASA"
        }
    }

    // Normaliza strings legadas/variações para o enum
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

    // Título usado no header da tela de treinos
    var titulo: String {
        switch self {
        case .crossfit: return "Treinos Crossfit"
        case .academia: return "Treinos Academia"
        case .emCasa:   return "Treinos em Casa"
        }
    }

    // Título breve exibido sobre a imagem principal
    var tituloOverlayImagem: String {
        displayName
    }

    // Nome da imagem principal associada a cada tipo
    var imagemCorpo: String {
        switch self {
        case .crossfit: return "rdv_treino1_vertical"
        case .academia: return "rdv_treino2_vertical"
        case .emCasa:   return "rdv_treino3_vertical"
        }
    }

    // Ícone customizado exibido no rodapé da tela de treinos
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
