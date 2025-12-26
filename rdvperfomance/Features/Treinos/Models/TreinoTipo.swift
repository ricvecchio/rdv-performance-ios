import SwiftUI

// MARK: - Tipos de treino
// Enum responsável por representar os tipos de treino disponíveis no app.
// Centraliza títulos, imagens e ícones relacionados a cada tipo.
enum TreinoTipo: String, Hashable {

    case crossfit
    case academia
    case emCasa

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
        switch self {
        case .crossfit: return "Crossfit"
        case .academia: return "Academia"
        case .emCasa:   return "Treinos em Casa"
        }
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
            // Ícone específico para Crossfit
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 20))

        case .academia:
            // Ícone de halter para Academia
            Image(systemName: "dumbbell")
                .font(.system(size: 20))

        case .emCasa:
            // Combinação de ícones para Treinos em Casa
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

