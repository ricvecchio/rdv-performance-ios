import SwiftUI

// MARK: - Tipos de treino
// Enum responsável por representar os tipos de treino disponíveis no app.
// Centraliza títulos, imagens e ícones relacionados a cada tipo.
enum TreinoTipo: String, Hashable {

    case crossfit
    case academia
    case emCasa

    // MARK: - UI Helpers (evita String(describing:) espalhado)

    /// Nome curto para UI ("Crossfit", "Academia", "Treinos em Casa")
    var displayName: String {
        switch self {
        case .crossfit: return "Crossfit"
        case .academia: return "Academia"
        case .emCasa:   return "Treinos em Casa"
        }
    }

    /// Chave padronizada para Firestore (ex: "CROSSFIT")
    /// (se preferir salvar minúsculo no Firestore, troque para `rawValue`)
    var firestoreKey: String {
        switch self {
        case .crossfit: return "CROSSFIT"
        case .academia: return "ACADEMIA"
        case .emCasa:   return "EMCASA"
        }
    }

    /// Normaliza valor vindo do AppStorage / Firestore quando existem legados
    /// Ex: "CROSSFIT" -> .crossfit, "emcasa" -> .emCasa, "EMCASA" -> .emCasa
    static func normalized(from any: String) -> TreinoTipo? {
        let v = any.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1) tenta direto com rawValue atual
        if let t = TreinoTipo(rawValue: v) { return t }

        // 2) tenta versões comuns/legadas (upper/lower)
        let lower = v.lowercased()
        if let t = TreinoTipo(rawValue: lower) { return t }

        // 3) mapeia chaves do firestore (upper) para enum
        let upper = v.uppercased()
        switch upper {
        case "CROSSFIT": return .crossfit
        case "ACADEMIA": return .academia
        case "EMCASA", "EM_CASA", "EM CASA": return .emCasa
        default: return nil
        }
    }

    // MARK: - Texto / Imagens

    // Título exibido no header da tela de treinos
    var titulo: String {
        switch self {
        case .crossfit: return "Treinos Crossfit"
        case .academia: return "Treinos Academia"
        case .emCasa:   return "Treinos em Casa"
        }
    }

    // Texto exibido sobre a imagem principal da tela de treinos
    var tituloOverlayImagem: String {
        displayName
    }

    // Nome da imagem principal associada a cada tipo de treino
    var imagemCorpo: String {
        switch self {
        case .crossfit: return "rdv_treino1_vertical"
        case .academia: return "rdv_treino2_vertical"
        case .emCasa:   return "rdv_treino3_vertical"
        }
    }

    // Ícone personalizado exibido no item central do rodapé da tela de treinos
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

