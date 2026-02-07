import Foundation

enum DefaultWorkoutsCrossfit {

    static func defaults(sectionKey: String) -> [DefaultWorkoutSeed] {

        // ✅ Somente no menu "Girls WODs"
        if sectionKey == "girlsWods" {
            return [
                DefaultWorkoutSeed(
                    name: "CINDY",
                    title: "Cindy – AMRAP icônico para capacidade aeróbica",
                    description: "AMRAP icônico para capacidade aeróbica.",
                    blocks: [
                        .init(title: "Aquecimento", text: "EMOM leve de movimentos do WOD.", order: 1),
                        .init(title: "Técnica", text: "Boa postura e transições rápidas.", order: 2),
                        .init(title: "WOD", text: """
AMRAP 20 min:
5 Pull-ups
10 Push-ups
15 Squats
""", order: 3),
                        .init(title: "Cargas / Movimentos", text: """
Iniciante: Ring rows / joelhos no chão
Scale: Pull-ups assistidos
RX: Prescrito
""", order: 4)
                    ]
                ),
                DefaultWorkoutSeed(
                    name: "ANGIE",
                    title: "Angie – Clássico de Volume Corporal",
                    description: "Um benchmark puro de resistência muscular e capacidade mental.",
                    blocks: [
                        .init(title: "Aquecimento", text: """
3 rounds leves:
- 10 air squats
- 10 sit-ups
- 5 pull-ups
Mobilidade de ombros e quadril
""", order: 1),
                        .init(title: "Detalhes", text: "Treino contínuo, sem divisão obrigatória de séries.", order: 2),
                        .init(title: "Técnica", text: """
Pull-ups com escápulas ativas
Push-ups com core firme
Squats completos
""", order: 3),
                        .init(title: "WOD", text: """
For time:
100 Pull-ups
100 Push-ups
100 Sit-ups
100 Squats
""", order: 4),
                        .init(title: "Cargas / Movimentos", text: """
Iniciante: 50 reps de cada / ring rows
Scale: 75 reps / pull-ups com elástico
RX: Conforme prescrito
""", order: 5)
                    ]
                ),
                DefaultWorkoutSeed(
                    name: "BARBARA",
                    title: "Barbara – Resistência Intervalada",
                    description: "Benchmark de volume e recuperação ativa.",
                    blocks: [
                        .init(title: "Aquecimento", text: """
Corrida leve + mobilidade
1 round reduzido do WOD
""", order: 1),
                        .init(title: "Detalhes", text: "Descanso obrigatório de 3 minutos entre rounds.", order: 2),
                        .init(title: "Técnica", text: "Controle respiratório e pacing.", order: 3),
                        .init(title: "WOD", text: """
5 rounds, each for time of:
20 Pull-ups
30 Push-ups
40 Sit-ups
50 Squats

Rest 3 min entre rounds
""", order: 4),
                        .init(title: "Cargas / Movimentos", text: """
Iniciante: Metade das reps
Scale: Pull-ups com elástico
RX: Prescrito
""", order: 5)
                    ]
                )
            ]
        }

        return []
    }
}

